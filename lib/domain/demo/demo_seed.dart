import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/child.dart';
import '../../data/models/measurement.dart';
import '../../data/repo/child_repository.dart';
import '../../data/repo/measurement_repository.dart';
import '../../data/repo/nutrition_repository.dart';
import '../../data/repo/progress_repository.dart';

/// Seeds fictional, non-sensitive content for store screenshots only.
class DemoSeed {
  DemoSeed._();

  static const _enabled = bool.fromEnvironment('ARUNIKA_DEMO_DATA');
  static const _seededKey = 'arunika_demo_seeded_v1';
  static const _onboardingKey = 'onboarding_done';
  static const _selectedChildKey = 'selected_child_id';

  static Future<void> seedIfEnabled(SharedPreferences prefs) async {
    if (!_enabled || !kDebugMode || prefs.getBool(_seededKey) == true) return;

    final childrenRepo = ChildRepository();
    if ((await childrenRepo.getAll()).isNotEmpty) {
      await prefs.setBool(_seededKey, true);
      return;
    }

    final today = DateTime.now();
    final alya = Child(
      id: 'demo-alya',
      name: 'Alya',
      gender: Gender.girl,
      birthDate: DateTime(today.year - 2, today.month - 8, today.day),
      birthWeight: 3.2,
      birthHeight: 49,
      fatherHeight: 172,
      motherHeight: 160,
      createdAt: today.millisecondsSinceEpoch,
    );
    final raka = Child(
      id: 'demo-raka',
      name: 'Raka',
      gender: Gender.boy,
      birthDate: DateTime(today.year - 5, today.month, today.day),
      birthWeight: 3.4,
      birthHeight: 50,
      fatherHeight: 175,
      motherHeight: 162,
      createdAt: today.millisecondsSinceEpoch + 1,
    );

    await childrenRepo.insert(alya);
    await childrenRepo.insert(raka);

    final measurementsRepo = MeasurementRepository();
    await _insertMeasurements(measurementsRepo, alya.id, [
      _measurement('alya-1', alya.id, today, -6, 11.7, 87.8, 47.2),
      _measurement('alya-2', alya.id, today, -4, 12.1, 89.4, 47.5),
      _measurement('alya-3', alya.id, today, -2, 12.7, 91.2, 47.8),
      _measurement(
        'alya-4',
        alya.id,
        today,
        -1,
        13.2,
        93.0,
        48.1,
        'Aktif dan nafsu makan baik',
      ),
    ]);
    await _insertMeasurements(measurementsRepo, raka.id, [
      _measurement('raka-1', raka.id, today, -8, 17.6, 108.2, 50.4),
      _measurement('raka-2', raka.id, today, -5, 18.3, 110.5, 50.8),
      _measurement('raka-3', raka.id, today, -2, 19.1, 112.7, 51.2),
      _measurement(
        'raka-4',
        raka.id,
        today,
        -1,
        19.7,
        114.0,
        51.5,
        'Pengukuran rutin',
      ),
    ]);

    final progressRepo = ProgressRepository();
    for (final id in [
      'gm_24_run',
      'gm_24_kick',
      'fm_24_tower4',
      'lg_24_2words',
      'sc_24_parallel',
      'gm_30_jump',
      'fm_30_turnpage',
      'lg_30_pronoun',
    ]) {
      await progressRepo.setMilestoneAchieved(alya.id, id, true);
    }
    for (final id in [
      'hb0',
      'bcg',
      'polio1',
      'dpt1',
      'polio2',
      'mr1',
      'pcv1',
      'flu1',
    ]) {
      await progressRepo.setImmunizationDone(alya.id, id, true);
    }

    final nutritionRepo = NutritionRepository();
    for (final id in [
      'main_meals',
      'animal_protein',
      'veggie_fruit',
      'water',
    ]) {
      await nutritionRepo.setItem(alya.id, today, id, true);
    }

    await prefs.setString(_selectedChildKey, alya.id);
    await prefs.setBool(_onboardingKey, true);
    await prefs.setBool(_seededKey, true);
  }

  static Measurement _measurement(
    String id,
    String childId,
    DateTime today,
    int monthsAgo,
    double weight,
    double height,
    double head, [
    String? note,
  ]) {
    return Measurement(
      id: id,
      childId: childId,
      date: DateTime(today.year, today.month + monthsAgo, today.day),
      weight: weight,
      height: height,
      head: head,
      createdAt: today.millisecondsSinceEpoch,
      note: note,
    );
  }

  static Future<void> _insertMeasurements(
    MeasurementRepository repository,
    String childId,
    List<Measurement> measurements,
  ) async {
    for (final measurement in measurements) {
      await repository.insert(measurement);
    }
  }
}
