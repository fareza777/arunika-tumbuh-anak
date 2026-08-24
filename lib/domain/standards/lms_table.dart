import 'dart:math' as math;

/// Satu baris parameter LMS (Box-Cox power L, median M, koefisien variasi S).
class LmsEntry {
  const LmsEntry({
    required this.x,
    required this.l,
    required this.m,
    required this.s,
  });
  final double x;
  final double l;
  final double m;
  final double s;
}

/// Tabel LMS dengan interpolasi linear antar titik.
///
/// Z-score:  z = ((X/M)^L − 1) / (L·S)   (L ≠ 0)
///           z = ln(X/M) / S             (L = 0)
///
/// Untuk |z| > 3 dipakai koreksi ekor WHO (berbasis selisih kurva SD2/SD3),
/// sesuai rekomendasi WHO Anthro untuk penilaian individu.
class LmsTable {
  LmsTable({required this.x, required this.l, required this.m, required this.s})
    : assert(
        x.length == l.length && l.length == m.length && m.length == s.length,
      );

  final List<double> x;
  final List<double> l;
  final List<double> m;
  final List<double> s;

  double get minX => x.first;
  double get maxX => x.last;
  int get length => x.length;

  factory LmsTable.fromJson(Map<String, dynamic> json) {
    List<double> col(String key) =>
        (json[key] as List).map((e) => (e as num).toDouble()).toList();
    return LmsTable(x: col('x'), l: col('l'), m: col('m'), s: col('s'));
  }

  bool covers(double xValue) => xValue >= minX && xValue <= maxX;

  /// Interpolasi linear parameter LMS pada posisi [xValue].
  /// Mengembalikan null bila di luar rentang tabel.
  LmsEntry? entryAt(double xValue) {
    if (xValue < minX || xValue > maxX) return null;

    // Cari segmen [i, i+1] yang memuat xValue.
    var lo = 0;
    var hi = x.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (x[mid] <= xValue) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final x0 = x[lo], x1 = x[hi];
    final t = (x1 == x0) ? 0.0 : (xValue - x0) / (x1 - x0);
    double lerp(List<double> c) => c[lo] + (c[hi] - c[lo]) * t;
    return LmsEntry(x: xValue, l: lerp(l), m: lerp(m), s: lerp(s));
  }

  /// Z-score mentah dari rumus LMS.
  double _rawZ(double value, LmsEntry e) {
    if (e.l.abs() < 1e-6) {
      return math.log(value / e.m) / e.s;
    }
    return (math.pow(value / e.m, e.l) - 1) / (e.l * e.s);
  }

  /// Nilai pengukuran pada z-score tertentu (kebalikan rumus LMS).
  double _valueForZEntry(double z, LmsEntry e) {
    if (e.l.abs() < 1e-6) {
      return e.m * math.exp(e.s * z);
    }
    return e.m * math.pow(1 + e.l * e.s * z, 1 / e.l);
  }

  /// Z-score untuk [value] pada umur/ukuran [xValue], dengan koreksi
  /// ekor WHO untuk |z| > 3. Null bila di luar rentang tabel.
  double? zFor(double value, double xValue) {
    if (value <= 0) return null;
    final e = entryAt(xValue);
    if (e == null) return null;

    final z = _rawZ(value, e);
    if (z > 3) {
      final sd3 = _valueForZEntry(3, e);
      final sd2 = _valueForZEntry(2, e);
      return 3 + (value - sd3) / (sd3 - sd2);
    }
    if (z < -3) {
      final sd3 = _valueForZEntry(-3, e);
      final sd2 = _valueForZEntry(-2, e);
      return -3 + (value - sd3) / (sd2 - sd3);
    }
    return z;
  }

  /// Nilai pengukuran pada z-score [z] dan posisi [xValue].
  double? valueForZ(double z, double xValue) {
    final e = entryAt(xValue);
    if (e == null) return null;
    return _valueForZEntry(z, e);
  }

  /// Kurva referensi: nilai pada z-score [z] untuk setiap titik x tabel.
  List<(double, double)> curveForZ(double z) {
    final points = <(double, double)>[];
    for (var i = 0; i < x.length; i++) {
      final e = LmsEntry(x: x[i], l: l[i], m: m[i], s: s[i]);
      points.add((x[i], _valueForZEntry(z, e)));
    }
    return points;
  }
}

/// Konversi z-score ↔ persentil (distribusi normal baku).
class NormalDist {
  NormalDist._();

  /// Persentil (0-100) dari z-score. Aproksimasi Abramowitz-Stegun.
  static double percentile(double z) {
    final p = _cdf(z);
    return (p * 100).clamp(0.01, 99.99);
  }

  static double _cdf(double z) {
    final t = 1 / (1 + 0.2316419 * z.abs());
    final d = 0.3989422804014327 * math.exp(-z * z / 2);
    var p =
        d *
        t *
        (0.3193815 +
            t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));
    if (z > 0) p = 1 - p;
    return p;
  }
}
