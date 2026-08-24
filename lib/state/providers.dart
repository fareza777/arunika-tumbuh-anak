import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/child.dart';
import '../data/models/measurement.dart';
import '../data/repo/child_repository.dart';
import '../data/repo/measurement_repository.dart';
import '../data/repo/nutrition_repository.dart';
import '../data/repo/progress_repository.dart';
import '../domain/insight/growth_insights.dart';
import '../domain/standards/standards_repository.dart';
import '../domain/zscore/zscore_service.dart';
import 'app_settings.dart';

const _uuid = Uuid();

// ── Layanan inti ────────────────────────────────────────────────────────────

final childRepoProvider = Provider<ChildRepository>((ref) => ChildRepository());
final measurementRepoProvider = Provider<MeasurementRepository>(
  (ref) => MeasurementRepository(),
);
final progressRepoProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(),
);

/// Memuat tabel LMS resmi dari aset (WHO 2006, WHO 2007, CDC 2000).
final standardsProvider = FutureProvider<StandardsRepository>((ref) async {
  await StandardsRepository.instance.ensureLoaded();
  return StandardsRepository.instance;
});

final zScoreServiceProvider = Provider<ZScoreService>(
  (ref) => ZScoreService(StandardsRepository.instance),
);

final insightsProvider = Provider<GrowthInsights>(
  (ref) => GrowthInsights(StandardsRepository.instance),
);

// ── Daftar anak ─────────────────────────────────────────────────────────────

class ChildrenNotifier extends AsyncNotifier<List<Child>> {
  @override
  Future<List<Child>> build() => ref.read(childRepoProvider).getAll();

  Future<Child> addChild(Child child) async {
    await ref.read(childRepoProvider).insert(child);
    ref.invalidateSelf();
    return child;
  }

  Future<void> updateChild(Child child) async {
    await ref.read(childRepoProvider).update(child);
    ref.invalidateSelf();
  }

  Future<void> deleteChild(String id) async {
    await ref.read(childRepoProvider).delete(id);
    // Bila anak terpilih dihapus, kosongkan pilihan.
    if (ref.read(selectedChildIdProvider) == id) {
      ref.read(selectedChildIdProvider.notifier).select(null);
    }
    ref.invalidateSelf();
  }
}

final childrenProvider = AsyncNotifierProvider<ChildrenNotifier, List<Child>>(
  ChildrenNotifier.new,
);

// ── Anak terpilih ───────────────────────────────────────────────────────────

class SelectedChildNotifier extends Notifier<String?> {
  static const _key = 'selected_child_id';

  @override
  String? build() => ref.read(sharedPrefsProvider).getString(_key);

  void select(String? id) {
    state = id;
    final prefs = ref.read(sharedPrefsProvider);
    if (id == null) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, id);
    }
  }
}

final selectedChildIdProvider =
    NotifierProvider<SelectedChildNotifier, String?>(SelectedChildNotifier.new);

/// Anak terpilih; bila belum ada, otomatis anak pertama.
final selectedChildProvider = Provider<Child?>((ref) {
  final children = ref.watch(childrenProvider).valueOrNull;
  if (children == null || children.isEmpty) return null;
  final id = ref.watch(selectedChildIdProvider);
  for (final child in children) {
    if (child.id == id) return child;
  }
  return children.first;
});

// ── Pengukuran ──────────────────────────────────────────────────────────────

/// Riwayat pengukuran anak terpilih (urut tanggal naik).
final measurementsProvider = FutureProvider<List<Measurement>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return const [];
  return ref.read(measurementRepoProvider).getForChild(child.id);
});

/// Aksi tulis pengukuran; setelah sukses me-refresh provider terkait.
final measurementActionsProvider = Provider<MeasurementActions>((ref) {
  return MeasurementActions(ref);
});

class MeasurementActions {
  MeasurementActions(this._ref);
  final Ref _ref;

  Future<Measurement> add({
    required String childId,
    required DateTime date,
    double? weight,
    double? height,
    double? head,
    double? muac,
    String? note,
  }) async {
    final measurement = Measurement(
      id: _uuid.v4(),
      childId: childId,
      date: date,
      weight: weight,
      height: height,
      head: head,
      muac: muac,
      note: note,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _ref.read(measurementRepoProvider).insert(measurement);
    _ref.invalidate(measurementsProvider);
    return measurement;
  }

  Future<void> update(Measurement measurement) async {
    await _ref.read(measurementRepoProvider).update(measurement);
    _ref.invalidate(measurementsProvider);
  }

  Future<void> delete(String id) async {
    await _ref.read(measurementRepoProvider).delete(id);
    _ref.invalidate(measurementsProvider);
  }
}

// ── Analisis ────────────────────────────────────────────────────────────────

/// Analisis z-score untuk pengukuran terbaru anak terpilih.
final latestAnalysisProvider = Provider<MeasurementAnalysis?>((ref) {
  final child = ref.watch(selectedChildProvider);
  final measurements = ref.watch(measurementsProvider).valueOrNull;
  if (child == null || measurements == null || measurements.isEmpty) {
    return null;
  }
  final settings = ref.watch(settingsProvider);
  return ref
      .read(zScoreServiceProvider)
      .analyze(
        child: child,
        measurement: measurements.last,
        standard: settings.standard,
      );
});

// ── Milestone & imunisasi ───────────────────────────────────────────────────

final milestoneStatusProvider = FutureProvider<Map<String, DateTime?>>((
  ref,
) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return const {};
  return ref.read(progressRepoProvider).getMilestoneStatus(child.id);
});

final immunizationStatusProvider = FutureProvider<Map<String, DateTime?>>((
  ref,
) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return const {};
  return ref.read(progressRepoProvider).getImmunizationStatus(child.id);
});

final progressActionsProvider = Provider<ProgressActions>(
  (ref) => ProgressActions(ref),
);

class ProgressActions {
  ProgressActions(this._ref);
  final Ref _ref;

  Future<void> toggleMilestone(
    String childId,
    String milestoneId,
    bool achieved,
  ) async {
    await _ref
        .read(progressRepoProvider)
        .setMilestoneAchieved(childId, milestoneId, achieved);
    _ref.invalidate(milestoneStatusProvider);
  }

  Future<void> toggleImmunization(
    String childId,
    String vaccineId,
    bool done,
  ) async {
    await _ref
        .read(progressRepoProvider)
        .setImmunizationDone(childId, vaccineId, done);
    _ref.invalidate(immunizationStatusProvider);
  }
}

/// Helper membuat ID anak baru.
String newChildId() => _uuid.v4();

// ── Gizi harian ─────────────────────────────────────────────────────────────

final nutritionRepoProvider = Provider<NutritionRepository>(
  (ref) => NutritionRepository(),
);

/// Item checklist gizi yang sudah dicentang hari ini untuk anak terpilih.
final nutritionTodayProvider = FutureProvider<Set<String>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return const {};
  return ref
      .read(nutritionRepoProvider)
      .getCheckedItems(child.id, DateTime.now());
});

final nutritionActionsProvider = Provider<NutritionActions>(
  (ref) => NutritionActions(ref),
);

class NutritionActions {
  NutritionActions(this._ref);
  final Ref _ref;

  Future<void> toggle(String childId, String itemId, bool checked) async {
    await _ref
        .read(nutritionRepoProvider)
        .setItem(childId, DateTime.now(), itemId, checked);
    _ref.invalidate(nutritionTodayProvider);
  }
}
