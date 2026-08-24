import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/luxe_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_ring.dart';
import '../../domain/standards/growth_standards.dart';
import '../../state/providers.dart';

/// Insight: ringkasan z-score, velocity pertumbuhan, prediksi tinggi dewasa.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final analysis = ref.watch(latestAnalysisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insight & Prediksi')),
      body: child == null || analysis == null
          ? const EmptyState(
              icon: Icons.favorite_rounded,
              title: 'Belum Ada Insight',
              message:
                  'Catat minimal satu pengukuran untuk melihat analisis mendalam si kecil.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // ── Ring persentil ───────────────────────────────────────
                const SectionHeader(title: 'Posisi Persentil'),
                LuxeCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final ind in [
                        GrowthIndicator.wfa,
                        GrowthIndicator.lhfa,
                        GrowthIndicator.bfa,
                      ])
                        _PercentileRing(analysis: analysis, indicator: ind),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Velocity ─────────────────────────────────────────────
                const SectionHeader(title: 'Kecepatan Tumbuh'),
                _VelocityCard(),
                const SizedBox(height: 22),

                // ── Prediksi tinggi dewasa ───────────────────────────────
                const SectionHeader(title: 'Prediksi Tinggi Dewasa'),
                _PredictionCard(),
                const SizedBox(height: 22),

                // ── Detail klasifikasi ───────────────────────────────────
                const SectionHeader(title: 'Detail Status Gizi'),
                for (final r in analysis.results)
                  LuxeCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconTile(
                              icon: r.classification.icon,
                              color: r.classification.color,
                              size: 40,
                              iconSize: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.indicator.label,
                                    style: AppTheme.sans(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: AppColors.inkFaint,
                                    ),
                                  ),
                                  Text(
                                    r.classification.label,
                                    style: AppTheme.serif(
                                      size: 16.5,
                                      weight: FontWeight.w600,
                                      color: r.classification.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ZBadge(
                              label: Format.z(r.z),
                              color: r.classification.color,
                              dense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          r.classification.advice,
                          style: AppTheme.sans(
                            size: 12.5,
                            color: AppColors.inkSoft,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PercentileRing extends ConsumerWidget {
  const _PercentileRing({required this.analysis, required this.indicator});

  final dynamic analysis;
  final GrowthIndicator indicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = analysis.resultFor(indicator);
    if (result == null) {
      return StatRing(
        progress: 0,
        size: 86,
        color: AppColors.inkFaint,
        caption: indicator.shortLabel,
        center: Text(
          '—',
          style: AppTheme.serif(size: 18, color: AppColors.inkFaint),
        ),
      );
    }
    return StatRing(
      progress: (result.percentile / 100).clamp(0.0, 1.0),
      size: 86,
      color: result.classification.color as Color,
      caption: indicator.shortLabel,
      center: Text(
        Format.percentile(result.percentile),
        style: AppTheme.serif(size: 18, weight: FontWeight.w600),
      ),
    );
  }
}

class _VelocityCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final measurements =
        ref.watch(measurementsProvider).valueOrNull ?? const [];
    if (child == null) return const SizedBox.shrink();

    final velocity = ref
        .read(insightsProvider)
        .velocity(measurements, child.effectiveAgeInMonths);

    return LuxeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _VelocityStat(
                  label: 'Tinggi',
                  value: velocity.cmPerYear == null
                      ? '—'
                      : '${velocity.cmPerYear!.toStringAsFixed(1).replaceAll('.', ',')} cm/th',
                  icon: Icons.straighten_rounded,
                  color: AppColors.boy,
                ),
              ),
              Container(width: 1, height: 48, color: AppColors.hairline),
              Expanded(
                child: _VelocityStat(
                  label: 'Berat',
                  value: velocity.kgPerYear == null
                      ? '—'
                      : '${velocity.kgPerYear!.toStringAsFixed(1).replaceAll('.', ',')} kg/th',
                  icon: Icons.monitor_weight_rounded,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.hairline),
          const SizedBox(height: 12),
          Text(
            velocity.assessment,
            style: AppTheme.sans(
              size: 12.5,
              color: AppColors.inkSoft,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _VelocityStat extends StatelessWidget {
  const _VelocityStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: AppTheme.serif(size: 17, weight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppTheme.sans(
            size: 9.5,
            weight: FontWeight.w800,
            color: AppColors.inkFaint,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PredictionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final analysis = ref.watch(latestAnalysisProvider);
    if (child == null) return const SizedBox.shrink();

    final haz = analysis?.resultFor(GrowthIndicator.lhfa)?.z;
    final prediction = ref
        .read(insightsProvider)
        .predictAdultHeight(child: child, currentHaz: haz);

    return LuxeCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF3EDFB)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PredictionStat(
                  label: 'Estimasi Jalur Tumbuh',
                  value: prediction.trajectoryEstimate == null
                      ? '—'
                      : '${prediction.trajectoryEstimate!.toStringAsFixed(0)} cm',
                  caption: 'berdasarkan z-score saat ini',
                ),
              ),
              Container(width: 1, height: 56, color: AppColors.hairline),
              Expanded(
                child: _PredictionStat(
                  label: 'Target Genetik',
                  value: prediction.geneticTarget == null
                      ? '—'
                      : '${prediction.geneticTarget!.toStringAsFixed(0)} cm',
                  caption: prediction.geneticRange == null
                      ? 'dari tinggi orang tua'
                      : 'rentang ${prediction.geneticRange!.$1.toStringAsFixed(0)}-${prediction.geneticRange!.$2.toStringAsFixed(0)} cm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final note in prediction.notes)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: AppColors.inkFaint,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      note,
                      style: AppTheme.sans(
                        size: 11,
                        color: AppColors.inkSoft,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PredictionStat extends StatelessWidget {
  const _PredictionStat({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTheme.sans(
            size: 9.5,
            weight: FontWeight.w800,
            color: AppColors.inkFaint,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.serif(
            size: 26,
            weight: FontWeight.w600,
            color: AppColors.goldDeep,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: AppTheme.sans(
            size: 10,
            weight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
