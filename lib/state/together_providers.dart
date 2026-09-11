import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/models/family_member.dart';
import '../data/models/moment.dart';
import '../data/models/ritual.dart';
import '../data/repo/family_member_repository.dart';
import '../data/repo/moment_repository.dart';
import '../data/repo/ritual_repository.dart';
import '../domain/together/recap_service.dart';
import '../domain/together/journal_media_store.dart';
import 'app_settings.dart';

const _togetherUuid = Uuid();

final journalTodayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final familyMemberRepositoryProvider = Provider<FamilyMemberRepository>(
  (ref) => FamilyMemberRepository(),
);
final ritualRepositoryProvider = Provider<RitualRepository>(
  (ref) => RitualRepository(),
);
final momentRepositoryProvider = Provider<MomentRepository>(
  (ref) => MomentRepository(),
);

final journalMediaStoreProvider = Provider<JournalMediaStore>(
  (ref) => JournalMediaStore(),
);

/// Nonfatal cleanup errors are separate from the result of a database save.
final journalStorageWarningProvider = StateProvider<String?>((ref) => null);

final familyMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  return ref.read(familyMemberRepositoryProvider).getAll();
});

class ActiveFamilyMemberNotifier extends Notifier<String?> {
  static const _key = 'active_family_member_id';

  @override
  String? build() => ref.read(sharedPrefsProvider).getString(_key);

  Future<void> select(String? id) async {
    state = id;
    final prefs = ref.read(sharedPrefsProvider);
    if (id == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, id);
    }
  }
}

final activeFamilyMemberIdProvider =
    NotifierProvider<ActiveFamilyMemberNotifier, String?>(
      ActiveFamilyMemberNotifier.new,
    );

final activeFamilyMemberProvider = Provider<FamilyMember?>((ref) {
  final members = ref.watch(familyMembersProvider).valueOrNull ?? const [];
  final selectedId = ref.watch(activeFamilyMemberIdProvider);
  for (final member in members) {
    if (member.id == selectedId) return member;
  }
  return members.isEmpty ? null : members.first;
});

final ritualsProvider = FutureProvider<List<Ritual>>((ref) async {
  return ref.read(ritualRepositoryProvider).getAll();
});

final archivedRitualsProvider = FutureProvider<List<Ritual>>((ref) async {
  final all = await ref
      .read(ritualRepositoryProvider)
      .getAll(includeArchived: true);
  return all.where((ritual) => ritual.isArchived).toList();
});

final todayRitualsProvider = FutureProvider<List<Ritual>>((ref) async {
  final rituals = await ref
      .read(ritualRepositoryProvider)
      .getScheduledFor(ref.watch(journalTodayProvider));
  return rituals;
});

final todayCompletedRitualIdsProvider = FutureProvider<Set<String>>((
  ref,
) async {
  return ref
      .read(ritualRepositoryProvider)
      .getCompletedIdsFor(ref.watch(journalTodayProvider));
});

final momentsProvider = FutureProvider<List<Moment>>((ref) async {
  return ref.read(momentRepositoryProvider).getAll();
});

final recapProvider = FutureProvider<WeeklyRecap>((ref) async {
  final today = ref.watch(journalTodayProvider);
  final moments = await ref.read(momentRepositoryProvider).getAll();
  final checkIns = await ref.read(ritualRepositoryProvider).getCheckIns();
  final rituals = await ref.read(ritualRepositoryProvider).getAll();
  return RecapService.build(
    moments: moments,
    checkIns: checkIns,
    rituals: rituals,
    now: today,
  );
});

final togetherActionsProvider = Provider<TogetherActions>(
  (ref) => TogetherActions(ref),
);

class TogetherActions {
  TogetherActions(this._ref);
  final Ref _ref;
  // The stable actions provider owns the queue for member and memory writes.
  // A file cannot be removed between another action's photo check and DB save.
  Future<void> _mediaWrites = Future<void>.value();

  Future<T> _serializeMediaWrite<T>(Future<T> Function() operation) {
    final result = _mediaWrites.then((_) => operation());
    _mediaWrites = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<FamilyMember> addMember({
    required String name,
    String? id,
    String role = 'family',
    String colorKey = 'sunrise',
  }) => _serializeMediaWrite(() async {
    final repository = _ref.read(familyMemberRepositoryProvider);
    final previous = id == null
        ? null
        : (await repository.getAll())
              .where((item) => item.id == id)
              .firstOrNull;
    final member =
        previous?.copyWith(name: name.trim(), role: role, colorKey: colorKey) ??
        FamilyMember(
          id: id ?? _togetherUuid.v4(),
          name: name.trim(),
          role: role,
          colorKey: colorKey,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
    await repository.insert(member);
    _ref.invalidate(familyMembersProvider);
    return member;
  });

  Future<void> updateMember(
    FamilyMember member,
  ) => _serializeMediaWrite(() async {
    final repository = _ref.read(familyMemberRepositoryProvider);
    final previous = (await repository.getAll())
        .where((item) => item.id == member.id)
        .firstOrNull;
    final photo = await _preparePhoto(member.photoPath, previous?.photoPath);
    final saved = photo.path == null
        ? member
        : member.copyWith(photoPath: photo.path);
    try {
      await repository.update(saved);
    } catch (_) {
      await _removePhotoIfUnused(photo.createdPath);
      rethrow;
    }
    _ref.invalidate(familyMembersProvider);
    if (previous?.photoPath != saved.photoPath) {
      await _removePhotoIfUnused(previous?.photoPath);
    }
    // Updating a member concurrently deleted outside this action layer may be
    // a no-op; do not leave a newly copied image without a stored association.
    await _removePhotoIfUnused(photo.createdPath);
  });

  Future<void> deleteMember(String id) => _serializeMediaWrite(() async {
    final repository = _ref.read(familyMemberRepositoryProvider);
    final previous = (await repository.getAll())
        .where((item) => item.id == id)
        .firstOrNull;
    await repository.delete(id);
    _ref.invalidate(familyMembersProvider);
    _ref.invalidate(momentsProvider);
    _ref.invalidate(recapProvider);
    await _removePhotoIfUnused(previous?.photoPath);
  });

  Future<void> saveRitual(Ritual ritual) async {
    await _ref.read(ritualRepositoryProvider).save(ritual);
    _refreshRituals();
  }

  Future<void> archiveRitual(String id) async {
    await _ref.read(ritualRepositoryProvider).archive(id);
    _refreshRituals();
  }

  Future<void> setRitualCheckIn(
    String ritualId,
    bool completed, {
    DateTime? date,
  }) async {
    await _ref
        .read(ritualRepositoryProvider)
        .setCheckIn(ritualId, date ?? DateTime.now(), completed);
    _ref.invalidate(todayCompletedRitualIdsProvider);
    _ref.invalidate(recapProvider);
  }

  Future<void> saveMoment(Moment moment) => _serializeMediaWrite(() async {
    final repository = _ref.read(momentRepositoryProvider);
    final previous = (await repository.getAll())
        .where((item) => item.id == moment.id)
        .firstOrNull;
    final photo = await _preparePhoto(moment.photoPath, previous?.photoPath);
    final saved = photo.path == null
        ? moment
        : moment.copyWith(photoPath: photo.path);
    try {
      await repository.save(saved);
    } catch (_) {
      await _removePhotoIfUnused(photo.createdPath);
      rethrow;
    }
    _ref.invalidate(momentsProvider);
    _ref.invalidate(recapProvider);
    if (previous?.photoPath != saved.photoPath) {
      await _removePhotoIfUnused(previous?.photoPath);
    }
  });

  Future<void> deleteMoment(String id) => _serializeMediaWrite(() async {
    final repository = _ref.read(momentRepositoryProvider);
    final previous = (await repository.getAll())
        .where((item) => item.id == id)
        .firstOrNull;
    await repository.delete(id);
    _ref.invalidate(momentsProvider);
    _ref.invalidate(recapProvider);
    await _removePhotoIfUnused(previous?.photoPath);
  });

  Future<({String? path, String? createdPath})> _preparePhoto(
    String? path,
    String? previousPath,
  ) async {
    if (path == null) return (path: null, createdPath: null);
    // Preserve editable text even when an old picker cache image was lost.
    if (path == previousPath && !await File(path).exists()) {
      return (path: path, createdPath: null);
    }
    final source = await File(path).resolveSymbolicLinks();
    final stored = await _ref
        .read(journalMediaStoreProvider)
        .persistPhoto(source);
    return (
      path: stored,
      createdPath: p.equals(source, stored) ? null : stored,
    );
  }

  Future<void> _removePhotoIfUnused(String? path) async {
    if (path == null) return;
    try {
      final candidate = await _canonicalPhotoPath(path);
      final moments = await _ref.read(momentRepositoryProvider).getAll();
      final members = await _ref.read(familyMemberRepositoryProvider).getAll();
      for (final reference in [
        ...moments.map((item) => item.photoPath),
        ...members.map((item) => item.photoPath),
      ].whereType<String>()) {
        if (p.equals(candidate, await _canonicalPhotoPath(reference))) return;
      }
      await _ref.read(journalMediaStoreProvider).deleteManagedPhoto(path);
    } on ArgumentError {
      // Gallery files and files owned by the old product are never ours to erase.
    } catch (_) {
      // Never turn a successfully committed edit/delete into a reported failure.
      // Retain the unreferenced file if ownership/references cannot be checked.
      _ref.read(journalStorageWarningProvider.notifier).state =
          'Sebagian berkas foto belum dapat dibersihkan dari perangkat.';
    }
  }

  Future<String> _canonicalPhotoPath(String path) async {
    try {
      return await File(path).resolveSymbolicLinks();
    } on FileSystemException {
      return p.normalize(p.absolute(path));
    }
  }

  Future<void> seedStarterRituals() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final starter = [
      Ritual(
        id: 'arunika-starter-bedtime-v1',
        title: 'Cerita sebelum tidur',
        description: 'Satu cerita, satu pelukan, tanpa buru-buru.',
        timeOfDay: RitualTimeOfDay.evening,
        accentKey: 'terracotta',
        createdAt: now,
      ),
      Ritual(
        id: 'arunika-starter-gratitude-v1',
        title: 'Tiga hal yang disyukuri',
        description: 'Saling berbagi satu hal kecil yang terasa baik.',
        timeOfDay: RitualTimeOfDay.evening,
        accentKey: 'gold',
        createdAt: now + 1,
      ),
      Ritual(
        id: 'arunika-starter-walk-v1',
        title: 'Jalan sebentar',
        description: 'Melihat langit dan dunia di sekitar bersama.',
        timeOfDay: RitualTimeOfDay.afternoon,
        accentKey: 'sage',
        repeatDays: const {6, 7},
        createdAt: now + 2,
      ),
    ];
    await _ref.read(ritualRepositoryProvider).insertStartersIfMissing(starter);
    _refreshRituals();
  }

  void _refreshRituals() {
    _ref.invalidate(archivedRitualsProvider);
    _ref.invalidate(ritualsProvider);
    _ref.invalidate(todayRitualsProvider);
    _ref.invalidate(todayCompletedRitualIdsProvider);
    _ref.invalidate(recapProvider);
  }
}
