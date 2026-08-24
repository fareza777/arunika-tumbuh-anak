import '../../data/models/child.dart';
import '../../data/models/measurement.dart';
import '../standards/growth_standards.dart';
import '../standards/standards_repository.dart';

/// Kecepatan pertumbuhan (growth velocity) tahunan.
class VelocityResult {
  const VelocityResult({
    required this.cmPerYear,
    required this.kgPerYear,
    required this.periodDays,
    required this.assessment,
  });

  final double? cmPerYear;
  final double? kgPerYear;
  final int periodDays;
  final String assessment;
}

/// Prediksi tinggi badan dewasa.
class AdultHeightPrediction {
  const AdultHeightPrediction({
    this.geneticTarget,
    this.geneticRange,
    this.trajectoryEstimate,
    required this.notes,
  });

  /// Target genetik (mid-parental height) dalam cm.
  final double? geneticTarget;

  /// Rentang target genetik (±8,5 cm).
  final (double, double)? geneticRange;

  /// Estimasi berdasarkan jalur (z-score) pertumbuhan saat ini, dalam cm.
  final double? trajectoryEstimate;

  final List<String> notes;
}

/// Analitik tumbuh kembang: velocity dan prediksi tinggi dewasa.
class GrowthInsights {
  GrowthInsights(this._standards);

  final StandardsRepository _standards;

  /// Menghitung velocity dengan regresi linear (least squares) atas
  /// maksimal 6 pengukuran terakhir yang membentang ≥ 28 hari.
  /// Jauh lebih tahan terhadap satu kesalahan ukur dibanding 2 titik.
  VelocityResult velocity(List<Measurement> history, double ageMonths) {
    final withHeight = history.where((m) => m.height != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final withWeight = history.where((m) => m.weight != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final heightFit = _slopePerYear([
      for (final m in withHeight) (m.date, m.height!),
    ]);
    final weightFit = _slopePerYear([
      for (final m in withWeight) (m.date, m.weight!),
    ]);

    return VelocityResult(
      cmPerYear: heightFit.value,
      kgPerYear: weightFit.value,
      periodDays: heightFit.spanDays > weightFit.spanDays
          ? heightFit.spanDays
          : weightFit.spanDays,
      assessment: _assessHeightVelocity(heightFit.value, ageMonths),
    );
  }

  /// Regresi linear titik (tanggal, nilai). Mengembalikan kenaikan per tahun
  /// (null bila titik < 2 atau rentang < 28 hari) beserta rentang harinya.
  ({double? value, int spanDays}) _slopePerYear(
    List<(DateTime, double)> points,
  ) {
    if (points.length < 2) return (value: null, spanDays: 0);

    // Maksimal 6 titik terakhir agar relevan dengan kondisi kini.
    final recent = points.length > 6
        ? points.sublist(points.length - 6)
        : points;
    final t0 = recent.first.$1;
    final xs = [for (final p in recent) p.$1.difference(t0).inDays.toDouble()];
    final ys = [for (final p in recent) p.$2];
    final span = xs.last.round();
    if (span < 28) return (value: null, spanDays: span);

    final n = xs.length;
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var i = 0; i < n; i++) {
      numerator += (xs[i] - meanX) * (ys[i] - meanY);
      denominator += (xs[i] - meanX) * (xs[i] - meanX);
    }
    if (denominator == 0) return (value: null, spanDays: span);
    return (value: numerator / denominator * 365.25, spanDays: span);
  }

  String _assessHeightVelocity(double? cmPerYear, double ageMonths) {
    if (cmPerYear == null) {
      return 'Tambahkan minimal dua pengukuran tinggi berjarak sebulan untuk melihat kecepatan tumbuh.';
    }
    // Norma kasar kecepatan tinggi (cm/tahun) berdasarkan usia.
    final double expected;
    if (ageMonths < 12) {
      expected = 25;
    } else if (ageMonths < 24) {
      expected = 12;
    } else if (ageMonths < 36) {
      expected = 8.5;
    } else if (ageMonths < 48) {
      expected = 7.5;
    } else if (ageMonths < 120) {
      expected = 6;
    } else {
      expected = 7; // masa pubertas, bervariasi
    }

    final ratio = cmPerYear / expected;
    if (ratio >= 0.85) {
      return 'Kecepatan tumbuh ${cmPerYear.toStringAsFixed(1)} cm/tahun — baik untuk usianya (acuan ±${expected.toStringAsFixed(0)} cm/tahun).';
    }
    if (ratio >= 0.6) {
      return 'Kecepatan tumbuh ${cmPerYear.toStringAsFixed(1)} cm/tahun — sedikit di bawah acuan ±${expected.toStringAsFixed(0)} cm/tahun. Pantau terus dan jaga nutrisi.';
    }
    return 'Kecepatan tumbuh ${cmPerYear.toStringAsFixed(1)} cm/tahun — di bawah acuan ±${expected.toStringAsFixed(0)} cm/tahun. Sebaiknya konsultasikan ke tenaga kesehatan.';
  }

  /// Prediksi tinggi dewasa: target genetik (mid-parental) dan
  /// estimasi jalur pertumbuhan (z-score saat ini diproyeksikan ke usia 19 th).
  AdultHeightPrediction predictAdultHeight({
    required Child child,
    required double? currentHaz,
  }) {
    final notes = <String>[];

    double? geneticTarget;
    (double, double)? geneticRange;
    final father = child.fatherHeight;
    final mother = child.motherHeight;
    if (father != null && mother != null) {
      geneticTarget = child.isBoy
          ? (father + mother + 13) / 2
          : (father + mother - 13) / 2;
      geneticRange = (geneticTarget - 8.5, geneticTarget + 8.5);
    } else {
      notes.add(
        'Isi tinggi Ayah dan Ibu di profil anak untuk melihat target genetik (mid-parental height).',
      );
    }

    double? trajectory;
    if (currentHaz != null) {
      // Proyeksikan z-score TB/U saat ini ke kurva WHO usia 19 tahun (228 bulan).
      final table = _standards.tableFor(
        standard: GrowthStandard.who2007,
        indicator: GrowthIndicator.lhfa,
        isBoy: child.isBoy,
        ageMonths: 228,
      );
      trajectory = table?.valueForZ(currentHaz.clamp(-3.0, 3.0), 228);
      if (trajectory != null) {
        notes.add(
          'Estimasi jalur mengasumsikan anak tetap berada pada jalur pertumbuhan (z-score) yang sama hingga dewasa.',
        );
      }
    } else {
      notes.add(
        'Belum ada pengukuran tinggi untuk menghitung estimasi jalur pertumbuhan.',
      );
    }

    notes.add(
      'Seluruh prediksi bersifat perkiraan statistik, bukan kepastian. Nutrisi, kesehatan, dan pola tidur sangat memengaruhi hasil akhir.',
    );

    return AdultHeightPrediction(
      geneticTarget: geneticTarget,
      geneticRange: geneticRange,
      trajectoryEstimate: trajectory,
      notes: notes,
    );
  }
}
