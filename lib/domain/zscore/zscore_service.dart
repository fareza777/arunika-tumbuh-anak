import '../../data/models/child.dart';
import '../../data/models/measurement.dart';
import '../standards/growth_standards.dart';
import '../standards/lms_table.dart';
import '../standards/standards_repository.dart';
import 'classification.dart';

/// Satu hasil indikator: z-score, persentil, dan klasifikasinya.
class IndicatorResult {
  const IndicatorResult({
    required this.indicator,
    required this.z,
    required this.percentile,
    required this.classification,
  });

  final GrowthIndicator indicator;
  final double z;
  final double percentile;
  final Classification classification;
}

/// Analisis lengkap satu pengukuran terhadap standar yang dipilih.
class MeasurementAnalysis {
  const MeasurementAnalysis({
    required this.standardUsed,
    required this.ageMonths,
    required this.bmi,
    required this.results,
    required this.muacClassification,
    required this.warnings,
  });

  final GrowthStandard standardUsed;
  final double ageMonths;
  final double? bmi;

  /// Hasil per indikator yang bisa dihitung.
  final List<IndicatorResult> results;

  /// Klasifikasi LILA bila diisi dan usia sesuai (6-59 bulan).
  final Classification? muacClassification;

  /// Catatan keterbatasan, mis. indikator di luar rentang standar.
  final List<String> warnings;

  IndicatorResult? resultFor(GrowthIndicator indicator) {
    for (final r in results) {
      if (r.indicator == indicator) return r;
    }
    return null;
  }

  /// Klasifikasi paling menonjol untuk ringkasan (prioritas BB/TB → IMT → BB/U).
  Classification? get headline {
    return resultFor(GrowthIndicator.wflh)?.classification ??
        resultFor(GrowthIndicator.bfa)?.classification ??
        resultFor(GrowthIndicator.wfa)?.classification;
  }
}

/// Menghitung z-score antropometri dari tabel LMS resmi.
class ZScoreService {
  ZScoreService(this._standards);

  final StandardsRepository _standards;

  MeasurementAnalysis analyze({
    required Child child,
    required Measurement measurement,
    required GrowthStandard standard,
  }) {
    // Penilaian memakai usia efektif: terkoreksi untuk bayi prematur < 24 bln.
    final ageMonths = child.effectiveAgeMonthsAt(measurement.date);
    final effective = _standards.resolveEffective(standard, ageMonths);
    final results = <IndicatorResult>[];
    final warnings = <String>[];

    if (child.usesCorrectedAge) {
      warnings.add(
        'Anak lahir prematur (${child.gestationalWeeks} mgg) — dinilai dengan usia terkoreksi.',
      );
    }

    void add(
      GrowthIndicator indicator,
      double? z,
      Classification Function(double z) classify,
    ) {
      if (z == null || z.isNaN || !z.isFinite) return;
      results.add(
        IndicatorResult(
          indicator: indicator,
          z: z,
          percentile: NormalDist.percentile(z),
          classification: classify(z),
        ),
      );
    }

    // ── BB/U ──────────────────────────────────────────────────────────────
    final weight = measurement.weight;
    if (weight != null) {
      final table = _standards.tableFor(
        standard: standard,
        indicator: GrowthIndicator.wfa,
        isBoy: child.isBoy,
        ageMonths: ageMonths,
      );
      final z = table?.zFor(weight, ageMonths);
      if (z != null) {
        add(GrowthIndicator.wfa, z, NutritionClassifier.weightForAge);
      } else {
        warnings.add(
          'BB/U berada di luar rentang standar ${effective.shortLabel} untuk usia ini.',
        );
      }
    }

    // ── TB/U ──────────────────────────────────────────────────────────────
    final height = measurement.height;
    if (height != null) {
      final table = _standards.tableFor(
        standard: standard,
        indicator: GrowthIndicator.lhfa,
        isBoy: child.isBoy,
        ageMonths: ageMonths,
      );
      final z = table?.zFor(height, ageMonths);
      if (z != null) {
        add(GrowthIndicator.lhfa, z, NutritionClassifier.heightForAge);
      } else {
        warnings.add(
          'TB/U berada di luar rentang standar ${effective.shortLabel} untuk usia ini.',
        );
      }
    }

    // ── BB/TB ─────────────────────────────────────────────────────────────
    if (weight != null && height != null) {
      final table = _standards.tableFor(
        standard: standard,
        indicator: GrowthIndicator.wflh,
        isBoy: child.isBoy,
        ageMonths: ageMonths,
      );
      final z = table?.zFor(weight, height);
      if (z != null) {
        add(GrowthIndicator.wflh, z, NutritionClassifier.weightForHeight);
      }
      // Tidak menambah warning: pada usia > 5 th indikator ini memang tidak dipakai.
    }

    // ── IMT/U ─────────────────────────────────────────────────────────────
    final bmi = measurement.bmi;
    if (bmi != null) {
      final table = _standards.tableFor(
        standard: standard,
        indicator: GrowthIndicator.bfa,
        isBoy: child.isBoy,
        ageMonths: ageMonths,
      );
      final z = table?.zFor(bmi, ageMonths);
      if (z != null) {
        add(
          GrowthIndicator.bfa,
          z,
          ageMonths <= 60.5
              ? NutritionClassifier.bmiForAgeUnder5
              : NutritionClassifier.bmiForAge5to19,
        );
      }
    }

    // ── LK/U ──────────────────────────────────────────────────────────────
    final head = measurement.head;
    if (head != null) {
      final table = _standards.tableFor(
        standard: standard,
        indicator: GrowthIndicator.hcfa,
        isBoy: child.isBoy,
        ageMonths: ageMonths,
      );
      final z = table?.zFor(head, ageMonths);
      if (z != null) {
        add(GrowthIndicator.hcfa, z, NutritionClassifier.headCircumference);
      }
    }

    // ── LILA (hanya 6-59 bulan) ───────────────────────────────────────────
    Classification? muacClass;
    final muac = measurement.muac;
    if (muac != null) {
      if (ageMonths >= 6 && ageMonths <= 59.9) {
        muacClass = NutritionClassifier.muac(muac);
      } else {
        warnings.add(
          'LILA sebagai skrining gizi berlaku untuk usia 6-59 bulan.',
        );
      }
    }

    return MeasurementAnalysis(
      standardUsed: effective,
      ageMonths: ageMonths,
      bmi: bmi,
      results: results,
      muacClassification: muacClass,
      warnings: warnings,
    );
  }
}
