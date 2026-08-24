import 'package:arunika_growth/data/models/child.dart';
import 'package:arunika_growth/data/models/measurement.dart';
import 'package:arunika_growth/domain/content/nutrition_data.dart';
import 'package:arunika_growth/domain/insight/growth_insights.dart';
import 'package:arunika_growth/domain/standards/standards_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Child _child({required DateTime birthDate, int? gestationalWeeks}) {
  return Child(
    id: 'test',
    name: 'Uji',
    gender: Gender.boy,
    birthDate: birthDate,
    gestationalWeeks: gestationalWeeks,
    createdAt: 0,
  );
}

Measurement _m(DateTime date, {double? weight, double? height}) {
  return Measurement(
    id: date.toIso8601String(),
    childId: 'test',
    date: date,
    weight: weight,
    height: height,
    createdAt: 0,
  );
}

void main() {
  group('Usia terkoreksi prematur', () {
    test('lahir 34 minggu: koreksi 42 hari diterapkan', () {
      final birth = DateTime(2026, 1, 1);
      final child = _child(birthDate: birth, gestationalWeeks: 34);
      final at = DateTime(2026, 4, 1); // 90 hari kronologis
      // 90 - (40-34)*7 = 48 hari terkoreksi.
      expect(child.effectiveAgeMonthsAt(at), closeTo(48 / 30.4375, 1e-9));
      expect(child.ageMonthsAt(at), closeTo(90 / 30.4375, 1e-9));
    });

    test('cukup bulan (>= 37 mgg) tidak dikoreksi', () {
      final birth = DateTime(2026, 1, 1);
      final child = _child(birthDate: birth, gestationalWeeks: 38);
      final at = DateTime(2026, 4, 1);
      expect(child.isPreterm, isFalse);
      expect(child.effectiveAgeMonthsAt(at), child.ageMonthsAt(at));
    });

    test('koreksi berhenti setelah usia kronologis 24 bulan', () {
      final birth = DateTime(2024, 1, 1);
      final child = _child(birthDate: birth, gestationalWeeks: 30);
      final at = DateTime(2026, 3, 1); // ~26 bulan
      expect(child.usesCorrectedAge, isFalse);
      expect(child.effectiveAgeMonthsAt(at), child.ageMonthsAt(at));
    });

    test('tanpa data kehamilan, perilaku tidak berubah', () {
      final child = _child(birthDate: DateTime(2026, 1, 1));
      expect(child.isPreterm, isFalse);
      expect(child.usesCorrectedAge, isFalse);
    });
  });

  group('Velocity regresi linear', () {
    final insights = GrowthInsights(StandardsRepository.instance);

    test('data linear sempurna menghasilkan slope yang tepat', () {
      final t0 = DateTime(2026, 1, 1);
      // Tumbuh persis 12 cm per tahun.
      final history = [
        _m(t0, height: 70),
        _m(t0.add(const Duration(days: 60)), height: 70 + 12 * 60 / 365.25),
        _m(t0.add(const Duration(days: 120)), height: 70 + 12 * 120 / 365.25),
      ];
      final v = insights.velocity(history, 36);
      expect(v.cmPerYear, closeTo(12, 0.01));
      expect(v.periodDays, 120);
    });

    test('satu outlier tidak merusak tren (robust terhadap salah ukur)', () {
      final t0 = DateTime(2026, 1, 1);
      final history = [
        _m(t0, height: 70),
        _m(t0.add(const Duration(days: 40)), height: 70.8),
        // Salah ukur: lonjakan tidak masuk akal.
        _m(t0.add(const Duration(days: 80)), height: 76),
        _m(t0.add(const Duration(days: 120)), height: 72.4),
      ];
      final v = insights.velocity(history, 36);
      // Tren asli ±7,3 cm/th; metode 2-titik-terakhir akan memberi nilai negatif besar.
      expect(v.cmPerYear!, greaterThan(0));
      expect(v.cmPerYear!, lessThan(14));
    });

    test('kurang dari 2 titik atau rentang < 28 hari → null', () {
      final t0 = DateTime(2026, 1, 1);
      expect(insights.velocity([], 36).cmPerYear, isNull);
      expect(insights.velocity([_m(t0, height: 70)], 36).cmPerYear, isNull);
      final tooClose = [
        _m(t0, height: 70),
        _m(t0.add(const Duration(days: 10)), height: 71),
      ];
      expect(insights.velocity(tooClose, 36).cmPerYear, isNull);
    });
  });

  group('Panduan gizi AKG 2019', () {
    test('kelompok usia memetakan angka resmi yang benar', () {
      expect(nutritionGuideFor(3).energyKkal, 550); // 0-5 bln
      expect(nutritionGuideFor(9).energyKkal, 800); // 6-11 bln
      expect(nutritionGuideFor(30).energyKkal, 1125); // 2-3 th
      expect(nutritionGuideFor(50).energyKkal, 1600); // 4-6 th
      expect(nutritionGuideFor(90).energyKkal, 1850); // 7-9 th
    });

    test('setiap panduan punya checklist & panduan porsi', () {
      for (final guide in kNutritionGuides) {
        expect(guide.checklist, isNotEmpty, reason: guide.ageLabel);
        expect(guide.frequency, isNotEmpty);
        expect(guide.portion, isNotEmpty);
      }
    });
  });
}
