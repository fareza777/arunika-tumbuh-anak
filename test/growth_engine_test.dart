import 'dart:convert';
import 'dart:io';

import 'package:arunika_growth/core/utils/format.dart';
import 'package:arunika_growth/domain/standards/lms_table.dart';
import 'package:arunika_growth/domain/zscore/classification.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uji mesin z-score terhadap ASET DATA RESMI yang dibundel
/// (WHO 2006, WHO 2007, CDC 2000) — bukan data tiruan.

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

LmsTable _table(Map<String, dynamic> json, String indicator, String sex) =>
    LmsTable.fromJson(
      (json[indicator] as Map<String, dynamic>)[sex] as Map<String, dynamic>,
    );

void main() {
  late Map<String, dynamic> who2006;
  late Map<String, dynamic> who2007;
  late Map<String, dynamic> cdc2000;

  setUpAll(() {
    who2006 = _loadJson('assets/standards/who2006.json');
    who2007 = _loadJson('assets/standards/who2007.json');
    cdc2000 = _loadJson('assets/standards/cdc2000.json');
  });

  group('Integritas aset standar', () {
    test('WHO 2006 memuat seluruh indikator 0-5 tahun', () {
      for (final key in ['wfa', 'lhfa', 'wfl', 'wfh', 'bfa', 'hcfa']) {
        expect(who2006.containsKey(key), isTrue, reason: 'kunci $key hilang');
        for (final sex in ['boys', 'girls']) {
          final t = _table(who2006, key, sex);
          expect(t.length, greaterThan(10));
          // x terurut naik.
          for (var i = 1; i < t.x.length; i++) {
            expect(t.x[i], greaterThan(t.x[i - 1]));
          }
        }
      }
    });

    test('WHO 2007 memuat rujukan 5-19 tahun', () {
      for (final key in ['bfa', 'hfa', 'wfa']) {
        expect(who2007.containsKey(key), isTrue, reason: 'kunci $key hilang');
      }
      // Rentang 61-228 bulan.
      final hfa = _table(who2007, 'hfa', 'boys');
      expect(hfa.minX, 61);
      expect(hfa.maxX, 228);
    });

    test('CDC 2000 memuat tabel infant & anak', () {
      for (final key in [
        'wtage',
        'statage',
        'bmiage',
        'wtageinf',
        'lenageinf',
        'wtleninf',
        'hcageinf',
        'wtstat',
      ]) {
        expect(cdc2000.containsKey(key), isTrue, reason: 'kunci $key hilang');
      }
    });
  });

  group('Mesin LMS dengan nilai resmi WHO 2006', () {
    test('median menghasilkan z ≈ 0 di berbagai usia', () {
      final wfa = _table(who2006, 'wfa', 'boys');
      for (final age in [0.0, 6.0, 12.0, 24.0, 48.0, 60.0]) {
        final e = wfa.entryAt(age)!;
        expect(wfa.zFor(e.m, age)!.abs(), lessThan(1e-9), reason: 'usia $age');
      }
    });

    test('round-trip valueForZ ↔ zFor konsisten', () {
      final lhfa = _table(who2006, 'lhfa', 'girls');
      for (final age in [3.0, 15.0, 30.0, 55.0]) {
        for (final z in [-2.5, -1.0, 0.0, 1.0, 2.5]) {
          final value = lhfa.valueForZ(z, age)!;
          final back = lhfa.zFor(value, age)!;
          expect(back, closeTo(z, 1e-6), reason: 'usia $age, z $z');
        }
      }
    });

    test('nilai referensi WHO yang diketahui publik', () {
      final wfaBoys = _table(who2006, 'wfa', 'boys');
      final lhfaBoys = _table(who2006, 'lhfa', 'boys');
      final lhfaGirls = _table(who2006, 'lhfa', 'girls');

      // Median BB lahir anak laki-laki WHO = 3,3464 kg.
      expect(wfaBoys.entryAt(0)!.m, closeTo(3.3464, 1e-4));
      // Median PB lahir anak laki-laki WHO = 49,8842 cm.
      expect(lhfaBoys.entryAt(0)!.m, closeTo(49.8842, 1e-3));
      // Median PB lahir anak perempuan WHO = 49,1477 cm.
      expect(lhfaGirls.entryAt(0)!.m, closeTo(49.1477, 1e-3));
      // Median BB anak laki-laki usia 9 bulan WHO = 8,9 kg (8,8-9,1).
      expect(wfaBoys.entryAt(9)!.m, inInclusiveRange(8.8, 9.1));
    });

    test('contoh klinis: anak laki-laki 9 bulan, 9,7 kg → z ≈ +0,79', () {
      final wfa = _table(who2006, 'wfa', 'boys');
      // Median WHO 9 bln = 8,9 kg dan +1 SD ≈ 9,9 kg, sehingga 9,7 kg
      // berada di antara keduanya, mendekati +0,8 SD (persentil ~79).
      final z = wfa.zFor(9.7, 9)!;
      expect(z, closeTo(0.79, 0.05));
    });

    test('koreksi ekor WHO untuk nilai ekstrem (|z| > 3)', () {
      final wfa = _table(who2006, 'wfa', 'boys');
      // Berat sangat besar pada usia 12 bulan → z jauh di atas +3.
      final zHigh = wfa.zFor(20.0, 12)!;
      expect(zHigh, greaterThan(3));
      // Berat sangat kecil → z jauh di bawah -3.
      final zLow = wfa.zFor(4.0, 12)!;
      expect(zLow, lessThan(-3));
    });

    test('interpolasi linear antar bulan', () {
      final wfa = _table(who2006, 'wfa', 'boys');
      final m6 = wfa.entryAt(6)!.m;
      final m7 = wfa.entryAt(7)!.m;
      final m65 = wfa.entryAt(6.5)!.m;
      expect(m65, closeTo((m6 + m7) / 2, 1e-9));
    });

    test('di luar rentang tabel mengembalikan null', () {
      final wfa = _table(who2006, 'wfa', 'boys');
      expect(wfa.entryAt(61), isNull);
      expect(wfa.zFor(10, -1), isNull);
    });
  });

  group('WHO 2007 & CDC 2000', () {
    test('median tinggi anak laki-laki 5 tahun (61 bln) WHO 2007 ≈ 110 cm', () {
      final hfa = _table(who2007, 'hfa', 'boys');
      expect(hfa.entryAt(61)!.m, inInclusiveRange(109.0, 111.0));
    });

    test('round-trip CDC wtage anak laki-laki', () {
      final wtage = _table(cdc2000, 'wtage', 'boys');
      for (final age in [24.0, 60.0, 120.0]) {
        for (final z in [-2.0, 0.0, 2.0]) {
          final value = wtage.valueForZ(z, age)!;
          expect(wtage.zFor(value, age)!, closeTo(z, 1e-6));
        }
      }
    });
  });

  group('Konversi persentil', () {
    test('nilai kunci distribusi normal', () {
      expect(NormalDist.percentile(0), closeTo(50, 0.01));
      expect(NormalDist.percentile(1.645), closeTo(95, 0.3));
      expect(NormalDist.percentile(-1.96), closeTo(2.5, 0.1));
      expect(NormalDist.percentile(2.326), closeTo(99, 0.3));
    });

    test('monoton naik', () {
      var prev = -1.0;
      for (var z = -3.0; z <= 3.0; z += 0.25) {
        final p = NormalDist.percentile(z);
        expect(p, greaterThan(prev));
        prev = p;
      }
    });
  });

  group('Klasifikasi Permenkes RI No. 2/2020', () {
    test('BB/U', () {
      expect(
        NutritionClassifier.weightForAge(-3.5).label,
        'Berat Badan Sangat Kurang',
      );
      expect(
        NutritionClassifier.weightForAge(-3.0).label,
        'Berat Badan Kurang',
      );
      expect(
        NutritionClassifier.weightForAge(-2.5).label,
        'Berat Badan Kurang',
      );
      expect(
        NutritionClassifier.weightForAge(-2.0).label,
        'Berat Badan Normal',
      );
      expect(NutritionClassifier.weightForAge(0).label, 'Berat Badan Normal');
      expect(NutritionClassifier.weightForAge(1.0).label, 'Berat Badan Normal');
      expect(
        NutritionClassifier.weightForAge(1.5).label,
        'Risiko Berat Badan Lebih',
      );
    });

    test('TB/U (stunting)', () {
      expect(NutritionClassifier.heightForAge(-3.5).label, 'Sangat Pendek');
      expect(NutritionClassifier.heightForAge(-2.5).label, 'Pendek');
      expect(NutritionClassifier.heightForAge(0).label, 'Tinggi Badan Normal');
      expect(NutritionClassifier.heightForAge(3.5).label, 'Tinggi');
    });

    test('BB/TB', () {
      expect(NutritionClassifier.weightForHeight(-3.5).label, 'Gizi Buruk');
      expect(NutritionClassifier.weightForHeight(-2.5).label, 'Gizi Kurang');
      expect(NutritionClassifier.weightForHeight(0).label, 'Gizi Baik');
      expect(
        NutritionClassifier.weightForHeight(1.5).label,
        'Berisiko Gizi Lebih',
      );
      expect(NutritionClassifier.weightForHeight(2.5).label, 'Gizi Lebih');
      expect(NutritionClassifier.weightForHeight(3.5).label, 'Obesitas');
    });

    test('IMT/U 5-19 tahun (WHO 2007)', () {
      expect(NutritionClassifier.bmiForAge5to19(-2.5).label, 'Kurus');
      expect(NutritionClassifier.bmiForAge5to19(0).label, 'Gizi Baik');
      expect(
        NutritionClassifier.bmiForAge5to19(1.5).label,
        'Berat Badan Lebih',
      );
      expect(NutritionClassifier.bmiForAge5to19(2.5).label, 'Obesitas');
    });

    test('LILA/MUAC 6-59 bulan', () {
      expect(NutritionClassifier.muac(11.0).level, StatusLevel.danger);
      expect(NutritionClassifier.muac(12.0).level, StatusLevel.warn);
      expect(NutritionClassifier.muac(13.0).level, StatusLevel.good);
    });
  });

  group('Format Indonesia', () {
    test('angka & satuan', () {
      expect(Format.kg(9.7), '9,7 kg');
      expect(Format.cm(75.5), '75,5 cm');
      expect(Format.z(0.791), '+0,79 SD');
      expect(Format.z(-1.234), '-1,23 SD');
      expect(Format.percentile(58.2), 'P58');
      expect(Format.decimal(3.3464, decimals: 2), '3,35');
    });

    test('usia', () {
      expect(Format.ageFromMonths(9), '9 bln');
      expect(Format.ageFromMonths(24), '2 th');
      expect(Format.ageFromMonths(27), '2 th 3 bln');
    });
  });
}
