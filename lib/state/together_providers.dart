import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/family_member.dart';
import '../data/models/moment.dart';
import '../data/models/ritual.dart';
import '../data/repo/family_member_repository.dart';
import '../data/repo/moment_repository.dart';
import '../data/repo/ritual_repository.dart';
import '../domain/together/recap_service.dart';
import 'app_settings.dart';

const _togetherUuid = Uuid();

final familyMemberRepositoryProvider = Provider<FamilyMemberRepository>(
  (ref) => FamilyMemberRepository(),
);
final ritualRepositoryProvider = Provider<RitualRepository>(
  (ref) => RitualRepository(),
);
final momentRepositoryProvider = Provider<MomentRepository>(
  (ref) => MomentRepository(),
);

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

final todayRitualsProvider = FutureProvider<List<Ritual>>((ref) async {
  final rituals = await ref
      .read(ritualRepositoryProvider)
      .getScheduledFor(DateTime.now());
  return rituals;
});

final todayCompletedRitualIdsProvider = FutureProvider<Set<String>>((
  ref,
) async {
  return ref.read(ritualRepositoryProvider).getCompletedIdsFor(DateTime.now());
});

final momentsProvider = FutureProvider<List<Moment>>((ref) async {
  return ref.read(momentRepositoryProvider).getRecent();
});

final recapProvider = FutureProvider<WeeklyRecap>((ref) async {
  final moments = await ref.read(momentRepositoryProvider).getAll();
  final checkIns = await ref.read(ritualRepositoryProvider).getCheckIns();
  final rituals = await ref.read(ritualRepositoryProvider).getAll();
  return RecapService.build(
    moments: moments,
    checkIns: checkIns,
    rituals: rituals,
  );
});

final togetherActionsProvider = Provider<TogetherActions>(
  (ref) => TogetherActions(ref),
);

class TogetherActions {
  TogetherActions(this._ref);
  final Ref _ref;

  Future<FamilyMember> addMember({
    required String name,
    String role = 'family',
    String colorKey = 'sunrise',
  }) async {
    final member = FamilyMember(
      id: _togetherUuid.v4(),
      name: name.trim(),
      role: role,
      colorKey: colorKey,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _ref.read(familyMemberRepositoryProvider).insert(member);
    _ref.invalidate(familyMembersProvider);
    await _ref.read(activeFamilyMemberIdProvider.notifier).select(member.id);
    return member;
  }

  Future<void> updateMember(FamilyMember member) async {
    await _ref.read(familyMemberRepositoryProvider).update(member);
    _ref.invalidate(familyMembersProvider);
  }

  Future<void> deleteMember(String id) async {
    await _ref.read(familyMemberRepositoryProvider).delete(id);
    if (_ref.read(activeFamilyMemberIdProvider) == id) {
      await _ref.read(activeFamilyMemberIdProvider.notifier).select(null);
    }
    _ref.invalidate(familyMembersProvider);
    _ref.invalidate(momentsProvider);
  }

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

  Future<void> saveMoment(Moment moment) async {
    await _ref.read(momentRepositoryProvider).save(moment);
    _ref.invalidate(momentsProvider);
    _ref.invalidate(recapProvider);
  }

  Future<void> deleteMoment(String id) async {
    await _ref.read(momentRepositoryProvider).delete(id);
    _ref.invalidate(momentsProvider);
    _ref.invalidate(recapProvider);
  }

  Future<void> seedStarterRituals() async {
    final existing = await _ref.read(ritualRepositoryProvider).getAll();
    if (existing.isNotEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final starter = [
      Ritual(
        id: _togetherUuid.v4(),
        title: 'Cerita sebelum tidur',
        description: 'Satu cerita, satu pelukan, tanpa buru-buru.',
        timeOfDay: RitualTimeOfDay.evening,
        accentKey: 'terracotta',
        createdAt: now,
      ),
      Ritual(
        id: _togetherUuid.v4(),
        title: 'Tiga hal yang disyukuri',
        description: 'Saling berbagi satu hal kecil yang terasa baik.',
        timeOfDay: RitualTimeOfDay.evening,
        accentKey: 'gold',
        createdAt: now + 1,
      ),
      Ritual(
        id: _togetherUuid.v4(),
        title: 'Jalan sebentar',
        description: 'Melihat langit dan dunia di sekitar bersama.',
        timeOfDay: RitualTimeOfDay.afternoon,
        accentKey: 'sage',
        repeatDays: const {6, 7},
        createdAt: now + 2,
      ),
    ];
    for (final ritual in starter) {
      await _ref.read(ritualRepositoryProvider).save(ritual);
    }
    _refreshRituals();
  }

  void _refreshRituals() {
    _ref.invalidate(ritualsProvider);
    _ref.invalidate(todayRitualsProvider);
    _ref.invalidate(todayCompletedRitualIdsProvider);
    _ref.invalidate(recapProvider);
  }
}
