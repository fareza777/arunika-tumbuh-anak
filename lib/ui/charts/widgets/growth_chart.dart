import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../domain/standards/growth_standards.dart';
import '../../../domain/standards/lms_table.dart';

/// Satu titik data anak pada grafik.
class ChildPoint {
  const ChildPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.tooltipLabel,
  });

  final double x;
  final double y;
  final double? z;

  /// Label ramah untuk tooltip, mis. "9 bln • 9,7 kg".
  final String tooltipLabel;
}

/// Grafik pertumbuhan premium: kurva referensi z-score (-3 s.d. +3),
/// zona hijau/kuning ala KMS, garis data anak, tooltip, pinch-zoom & geser.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.table,
    required this.indicator,
    required this.childPoints,
    required this.isBoy,
    this.currentAgeMonths,
    this.transformationController,
    this.compact = false,
  });

  final LmsTable table;
  final GrowthIndicator indicator;
  final List<ChildPoint> childPoints;
  final bool isBoy;

  /// Untuk garis penanda "usia saat ini" (hanya grafik berbasis umur).
  final double? currentAgeMonths;
  final TransformationController? transformationController;

  /// Mode ringkas (mis. untuk PDF): label lebih sedikit.
  final bool compact;

  static const _zLines = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0];

  @override
  Widget build(BuildContext context) {
    final curves = [for (final z in _zLines) table.curveForZ(z)];

    // Rentang sumbu.
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final curve in curves) {
      for (final p in curve) {
        if (p.$2 < minY) minY = p.$2;
        if (p.$2 > maxY) maxY = p.$2;
      }
    }
    for (final p in childPoints) {
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    if (!minY.isFinite || !maxY.isFinite) {
      minY = 0;
      maxY = 10;
    }
    final padY = (maxY - minY) * 0.06;
    minY = (minY - padY).clamp(0.0, double.infinity);
    maxY = maxY + padY;

    final minX = table.minX;
    final maxX = table.maxX;
    final isAge = indicator != GrowthIndicator.wflh;

    final bars = <LineChartBarData>[];

    LineChartBarData refLine(List<(double, double)> curve, int zi) {
      final z = _zLines[zi];
      final Color color;
      double width;
      List<int>? dash;
      if (z == 0) {
        color = AppColors.gold;
        width = 2.6;
      } else if (z == -1 || z == 1) {
        color = AppColors.inkFaint;
        width = 1.1;
        dash = [5, 4];
      } else if (z == -2 || z == 2) {
        color = AppColors.warn;
        width = 1.3;
      } else {
        color = AppColors.danger;
        width = 1.3;
        dash = [7, 4];
      }
      return LineChartBarData(
        spots: [for (final p in curve) FlSpot(p.$1, p.$2)],
        isCurved: true,
        curveSmoothness: 0.32,
        preventCurveOverShooting: true,
        color: color,
        barWidth: width,
        dashArray: dash,
        dotData: const FlDotData(show: false),
      );
    }

    for (var i = 0; i < curves.length; i++) {
      bars.add(refLine(curves[i], i));
    }

    // Garis data anak (index terakhir).
    final childBarIndex = bars.length;
    final childColor = AppColors.forGender(isBoy);
    bars.add(
      LineChartBarData(
        spots: [for (final p in childPoints) FlSpot(p.x, p.y)],
        isCurved: childPoints.length > 2,
        curveSmoothness: 0.3,
        preventCurveOverShooting: true,
        gradient: LinearGradient(
          colors: [AppColors.forGenderDeep(isBoy), childColor],
        ),
        barWidth: 3.4,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4.6,
            color: AppColors.forGenderDeep(isBoy),
            strokeColor: Colors.white,
            strokeWidth: 2.2,
          ),
        ),
        shadow: Shadow(color: childColor.withValues(alpha: 0.3), blurRadius: 6),
      ),
    );

    final xInterval = _niceInterval(maxX - minX, compact ? 4 : 6);
    final yInterval = _niceInterval(maxY - minY, compact ? 4 : 5);

    return LineChart(
      transformationConfig: FlTransformationConfig(
        scaleAxis: FlScaleAxis.horizontal,
        minScale: 1,
        maxScale: 8,
        panEnabled: true,
        scaleEnabled: true,
        transformationController: transformationController,
      ),
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        backgroundColor: Colors.transparent,
        lineBarsData: bars,
        betweenBarsData: [
          // Zona kuning bawah (z -3 s.d. -2).
          BetweenBarsData(
            fromIndex: 0,
            toIndex: 1,
            color: AppColors.warn.withValues(alpha: 0.10),
          ),
          // Zona hijau (z -2 s.d. +2).
          BetweenBarsData(
            fromIndex: 1,
            toIndex: 5,
            color: AppColors.good.withValues(alpha: 0.09),
          ),
          // Zona kuning atas (z +2 s.d. +3).
          BetweenBarsData(
            fromIndex: 5,
            toIndex: 6,
            color: AppColors.warn.withValues(alpha: 0.10),
          ),
        ],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (isAge &&
                currentAgeMonths != null &&
                currentAgeMonths! >= minX &&
                currentAgeMonths! <= maxX)
              VerticalLine(
                x: currentAgeMonths!,
                color: AppColors.goldDeep.withValues(alpha: 0.5),
                strokeWidth: 1.2,
                dashArray: [4, 5],
              ),
          ],
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: yInterval,
          verticalInterval: xInterval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.hairline, strokeWidth: 0.8),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: AppColors.hairline, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: compact ? 36 : 46,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _trimNumber(value),
                    textAlign: TextAlign.end,
                    style: AppTheme.sans(
                      size: compact ? 9 : 10.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: compact ? 24 : 32,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    isAge ? Format.axisMonths(value) : _trimNumber(value),
                    style: AppTheme.sans(
                      size: compact ? 9 : 10.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: childPoints.isNotEmpty,
          handleBuiltInTouches: true,
          touchSpotThreshold: 24,
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(14),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            getTooltipColor: (_) => AppColors.ink.withValues(alpha: 0.92),
            maxContentWidth: 190,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex != childBarIndex) {
                  return null; // hanya titik anak yang menampilkan tooltip
                }
                final point = childPoints[spot.spotIndex];
                final zText = point.z == null ? '' : '\n${Format.z(point.z)}';
                return LineTooltipItem(
                  '${point.tooltipLabel}$zText',
                  AppTheme.sans(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.4,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  static double _niceInterval(double range, int targetDivisions) {
    if (range <= 0) return 1;
    final raw = range / targetDivisions;
    final magnitude = (raw.abs()).toStringAsExponential(0);
    final exp = int.parse(magnitude.split('e')[1]);
    final base = [1, 2, 2.5, 5, 10];
    for (final b in base) {
      final interval = b * _pow10(exp);
      if (interval >= raw) return interval;
    }
    return 10 * _pow10(exp);
  }

  static double _pow10(int exp) {
    var result = 1.0;
    for (var i = 0; i < exp.abs(); i++) {
      result *= exp >= 0 ? 10 : 0.1;
    }
    return result;
  }

  static String _trimNumber(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1).replaceAll('.', ',');
  }
}
