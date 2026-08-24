import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app.dart';
import '../../core/utils/format.dart';
import '../../data/models/child.dart';
import '../../data/models/measurement.dart';
import '../standards/growth_standards.dart';
import '../standards/standards_repository.dart';
import '../zscore/zscore_service.dart';

/// Pembangkit laporan PDF premium: kurva digambar sebagai vektor sehingga
/// tajam saat dicetak, dengan tipografi font bundel aplikasi.
class PdfReportBuilder {
  PdfReportBuilder({required this.standards});

  final StandardsRepository standards;

  static final _gold = PdfColor.fromHex('#C29A3C');
  static final _goldDeep = PdfColor.fromHex('#8A6A2A');
  static final _goldMist = PdfColor.fromHex('#F6EEDC');
  static final _ink = PdfColor.fromHex('#2E2A24');
  static final _inkSoft = PdfColor.fromHex('#6E675C');
  static final _inkFaint = PdfColor.fromHex('#A79E90');
  static final _hairline = PdfColor.fromHex('#EAE3D4');
  static final _warn = PdfColor.fromHex('#D98E2B');
  static final _danger = PdfColor.fromHex('#C94F4F');

  Future<Uint8List> build({
    required Child child,
    required List<Measurement> measurements,
    required MeasurementAnalysis? latestAnalysis,
    required GrowthStandard standard,
    required bool includeCharts,
    required bool includeHistory,
  }) async {
    final sans = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
    );
    final sansBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'),
    );
    final serif = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Fraunces-SemiBold.ttf'),
    );

    final doc = pw.Document(
      title: 'Laporan Tumbuh Kembang ${child.name}',
      author: AppIdentity.fullName,
    );

    final theme = pw.ThemeData.withFont(base: sans, bold: sansBold);

    final widgets = <pw.Widget>[
      _childHeader(child, serif),
      pw.SizedBox(height: 18),
      if (latestAnalysis != null) ...[
        _sectionTitle('Ringkasan Pengukuran Terakhir', serif),
        pw.SizedBox(height: 8),
        _summaryTable(child, latestAnalysis, sans, sansBold),
        pw.SizedBox(height: 6),
        pw.Text(
          'Standar rujukan: ${standard.label}',
          style: pw.TextStyle(font: sans, fontSize: 8.5, color: _inkFaint),
        ),
        pw.SizedBox(height: 18),
      ],
      if (includeCharts && measurements.isNotEmpty) ...[
        _sectionTitle('Kurva Pertumbuhan', serif),
        pw.SizedBox(height: 10),
        for (final indicator in [
          GrowthIndicator.wfa,
          GrowthIndicator.lhfa,
          GrowthIndicator.wflh,
          GrowthIndicator.bfa,
          GrowthIndicator.hcfa,
        ])
          if (_hasData(measurements, indicator))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 16),
              child: _chartBlock(
                child,
                measurements,
                standard,
                indicator,
                sans,
                sansBold,
              ),
            ),
      ],
      if (includeHistory && measurements.isNotEmpty) ...[
        _sectionTitle('Riwayat Pengukuran', serif),
        pw.SizedBox(height: 8),
        _historyTable(child, measurements, sans, sansBold),
      ],
    ];

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 70, 42, 56),
          theme: theme,
        ),
        header: (context) => _pageHeader(sans, sansBold),
        footer: (context) => _pageFooter(context, sans),
        build: (context) => widgets,
      ),
    );

    return doc.save();
  }

  bool _hasData(List<Measurement> ms, GrowthIndicator indicator) {
    if (indicator == GrowthIndicator.wflh) {
      return ms.any((m) => m.weight != null && m.height != null);
    }
    return ms.any((m) => _valueOf(m, indicator) != null);
  }

  double? _valueOf(Measurement m, GrowthIndicator indicator) {
    return switch (indicator) {
      GrowthIndicator.wfa => m.weight,
      GrowthIndicator.lhfa => m.height,
      GrowthIndicator.wflh => null,
      GrowthIndicator.bfa => m.bmi,
      GrowthIndicator.hcfa => m.head,
    };
  }

  // ── Header & footer halaman ─────────────────────────────────────────────

  pw.Widget _pageHeader(pw.Font sans, pw.Font sansBold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 1.4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 22,
                height: 22,
                decoration: pw.BoxDecoration(
                  color: _gold,
                  borderRadius: pw.BorderRadius.circular(7),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'A',
                  style: pw.TextStyle(
                    font: sansBold,
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'ARUNIKA',
                style: pw.TextStyle(
                  font: sansBold,
                  fontSize: 13,
                  color: _goldDeep,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          pw.Text(
            'Laporan Tumbuh Kembang Anak',
            style: pw.TextStyle(font: sans, fontSize: 9, color: _inkSoft),
          ),
        ],
      ),
    );
  }

  pw.Widget _pageFooter(pw.Context context, pw.Font sans) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 8, bottom: 6),
          height: 0.6,
          color: _hairline,
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                'Dibuat oleh ${AppIdentity.fullName} • ${Format.date(DateTime.now())} • Alat bantu pemantauan, bukan pengganti diagnosis tenaga kesehatan.',
                style: pw.TextStyle(
                  font: sans,
                  fontSize: 7.5,
                  color: _inkFaint,
                ),
              ),
            ),
            pw.Text(
              'Hal. ${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(font: sans, fontSize: 7.5, color: _inkFaint),
            ),
          ],
        ),
      ],
    );
  }

  // ── Blok identitas anak ─────────────────────────────────────────────────

  pw.Widget _childHeader(Child child, pw.Font serif) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _goldMist,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _gold, width: 0.8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                child.name,
                style: pw.TextStyle(font: serif, fontSize: 22, color: _ink),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${child.gender.label} • Lahir ${Format.date(child.birthDate)}',
                style: pw.TextStyle(fontSize: 10, color: _inkSoft),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'USIA SAAT INI',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: _goldDeep,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                child.ageLabel,
                style: pw.TextStyle(
                  font: serif,
                  fontSize: 15,
                  color: _goldDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title, pw.Font serif) {
    return pw.Text(
      title,
      style: pw.TextStyle(font: serif, fontSize: 15, color: _ink),
    );
  }

  // ── Tabel ringkasan z-score ─────────────────────────────────────────────

  pw.Widget _summaryTable(
    Child child,
    MeasurementAnalysis analysis,
    pw.Font sans,
    pw.Font sansBold,
  ) {
    final rows = <List<String>>[];
    for (final r in analysis.results) {
      rows.add([
        r.indicator.label,
        Format.z(r.z),
        Format.percentile(r.percentile),
        r.classification.label,
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Indikator', 'Z-Score', 'Persentil', 'Status'],
      data: rows,
      headerStyle: pw.TextStyle(
        font: sansBold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      cellStyle: pw.TextStyle(font: sans, fontSize: 9, color: _ink),
      headerDecoration: pw.BoxDecoration(color: _goldDeep),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFFEAE3D4),
            width: 0.5,
          ),
        ),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerLeft,
      },
    );
  }

  // ── Grafik vektor ───────────────────────────────────────────────────────

  pw.Widget _chartBlock(
    Child child,
    List<Measurement> measurements,
    GrowthStandard standard,
    GrowthIndicator indicator,
    pw.Font sans,
    pw.Font sansBold,
  ) {
    // BB/TB memakai sumbu X = panjang/tinggi (cm); indikator lain = usia.
    final xIsAge = indicator != GrowthIndicator.wflh;

    // Titik anak untuk indikator ini (usia efektif: terkoreksi bila prematur).
    final points = <({double x, double value})>[];
    for (final m in measurements) {
      if (xIsAge) {
        final v = _valueOf(m, indicator);
        if (v != null) {
          points.add((x: child.effectiveAgeMonthsAt(m.date), value: v));
        }
      } else if (m.weight != null && m.height != null) {
        points.add((x: m.height!, value: m.weight!));
      }
    }
    if (points.isEmpty) return pw.SizedBox();
    points.sort((a, b) => a.x.compareTo(b.x));

    final table = standards.tableFor(
      standard: standard,
      indicator: indicator,
      isBoy: child.isBoy,
      ageMonths: child.effectiveAgeMonthsAt(measurements.last.date),
    );
    if (table == null) return pw.SizedBox();

    final maxChildX = points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    final xMin = xIsAge ? 0.0 : table.minX;
    final desiredMax = xIsAge
        ? (maxChildX + 3 < 24 ? 24.0 : maxChildX + 3)
        : (maxChildX + 5 < 65 ? 65.0 : maxChildX + 5);
    final xMax = desiredMax > table.maxX ? table.maxX : desiredMax;

    final datasets = <pw.LineDataSet<pw.PointChartValue>>[];
    var yMin = double.infinity;
    var yMax = double.negativeInfinity;

    // Kurva referensi z = -3 s.d. +3.
    for (final z in [-3, -2, -1, 0, 1, 2, 3]) {
      final curve = table
          .curveForZ(z.toDouble())
          .where((p) => p.$1 <= xMax && p.$1 >= xMin)
          .toList();
      for (final p in curve) {
        if (p.$2 < yMin) yMin = p.$2;
        if (p.$2 > yMax) yMax = p.$2;
      }
      final isMedian = z == 0;
      final color = isMedian
          ? _gold
          : z.abs() == 1
          ? _inkFaint
          : z.abs() == 2
          ? _warn
          : _danger;
      datasets.add(
        pw.LineDataSet<pw.PointChartValue>(
          data: [for (final p in curve) pw.PointChartValue(p.$1, p.$2)],
          drawPoints: false,
          isCurved: true,
          lineWidth: isMedian ? 1.4 : 0.7,
          color: color,
          lineColor: color,
        ),
      );
    }

    // Garis & titik pengukuran anak.
    for (final p in points) {
      if (p.value < yMin) yMin = p.value;
      if (p.value > yMax) yMax = p.value;
    }
    datasets.add(
      pw.LineDataSet<pw.PointChartValue>(
        data: [for (final p in points) pw.PointChartValue(p.x, p.value)],
        drawPoints: true,
        pointSize: 2.4,
        lineWidth: 1.6,
        color: _goldDeep,
        lineColor: _ink,
      ),
    );

    final pad = (yMax - yMin) * 0.06;
    yMin -= pad;
    yMax += pad;

    final xStep = xIsAge
        ? (xMax > 72 ? 12.0 : 6.0)
        : ((xMax - xMin) > 60 ? 20.0 : 10.0);
    final firstTick = xIsAge ? 0.0 : (xMin / xStep).ceil() * xStep;
    final xTicks = <double>[
      for (var a = firstTick; a <= xMax + 0.001; a += xStep) a,
    ];
    final yTicks = <double>[
      for (var i = 0; i <= 4; i++) yMin + (yMax - yMin) * i / 4,
    ];
    final yDecimals = yMax >= 100 ? 0 : 1;
    final axisStyle = pw.TextStyle(font: sans, fontSize: 7, color: _inkFaint);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${indicator.label} — ${child.gender.label}',
          style: pw.TextStyle(font: sansBold, fontSize: 10.5, color: _ink),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          height: 210,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _hairline, width: 0.8),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          padding: const pw.EdgeInsets.fromLTRB(2, 8, 10, 2),
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis(
                xTicks,
                format: (v) => '${v.round()}',
                textStyle: axisStyle,
                divisions: true,
                divisionsColor: _hairline,
                divisionsWidth: 0.4,
              ),
              yAxis: pw.FixedAxis(
                yTicks,
                format: (v) =>
                    Format.decimal(v.toDouble(), decimals: yDecimals),
                textStyle: axisStyle,
                divisions: true,
                divisionsColor: _hairline,
                divisionsWidth: 0.5,
              ),
            ),
            datasets: datasets,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Sumbu X: ${xIsAge ? 'usia (bulan)' : 'panjang/tinggi (cm)'}. Garis emas tebal = median (0 SD); abu = ±1 SD; kuning = ±2 SD; merah = ±3 SD.',
          style: pw.TextStyle(font: sans, fontSize: 7.5, color: _inkFaint),
        ),
      ],
    );
  }

  // ── Tabel riwayat ───────────────────────────────────────────────────────

  pw.Widget _historyTable(
    Child child,
    List<Measurement> measurements,
    pw.Font sans,
    pw.Font sansBold,
  ) {
    final rows = <List<String>>[];
    for (final m in measurements.reversed) {
      rows.add([
        Format.date(m.date),
        Format.ageFromMonths(child.ageMonthsAt(m.date)),
        m.weight == null ? '-' : Format.decimal(m.weight!),
        m.height == null ? '-' : Format.decimal(m.height!),
        m.bmi == null ? '-' : Format.decimal(m.bmi!),
        m.head == null ? '-' : Format.decimal(m.head!),
        m.muac == null ? '-' : Format.decimal(m.muac!),
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: [
        'Tanggal',
        'Usia',
        'BB (kg)',
        'TB (cm)',
        'IMT',
        'LK (cm)',
        'LILA (cm)',
      ],
      data: rows,
      headerStyle: pw.TextStyle(
        font: sansBold,
        fontSize: 8.5,
        color: PdfColors.white,
      ),
      cellStyle: pw.TextStyle(font: sans, fontSize: 8.5, color: _ink),
      headerDecoration: pw.BoxDecoration(color: _ink),
      oddRowDecoration: pw.BoxDecoration(color: _goldMist),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
      },
    );
  }
}
