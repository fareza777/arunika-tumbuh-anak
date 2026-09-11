import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:arunika_growth/data/db/app_database.dart';
import 'package:arunika_growth/data/models/family_member.dart';
import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/data/models/ritual.dart';
import 'package:arunika_growth/data/repo/family_member_repository.dart';
import 'package:arunika_growth/data/repo/moment_repository.dart';
import 'package:arunika_growth/data/repo/ritual_repository.dart';

void main() {
  late Directory directory;
  final database = AppDatabase.instance;
  final rituals = RitualRepository();
  final members = FamilyMemberRepository();
  final moments = MomentRepository();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('arunika-repository-');
    await databaseFactory.setDatabasesPath(directory.path);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('editing a ritual retains its completed days', () async {
    final ritual = Ritual(id: 'reading', title: 'Baca', createdAt: 1);
    await rituals.save(ritual);
    await rituals.setCheckIn('reading', DateTime(2026, 9, 1), true);
    await rituals.setCheckIn('reading', DateTime(2026, 9, 2), true);

    await rituals.save(ritual.copyWith(title: 'Baca bersama'));

    expect((await rituals.getAll()).single.title, 'Baca bersama');
    expect(
      (await rituals.getCheckIns()).map((item) => item.dayKey),
      unorderedEquals(['2026-09-01', '2026-09-02']),
    );
  });

  test('saving an existing member keeps memory associations', () async {
    final member = FamilyMember(id: 'ibu', name: 'Ibu', createdAt: 1);
    await members.insert(member);
    await moments.save(
      Moment(
        id: 'memory',
        title: 'Hari ini',
        note: 'Bersama ibu.',
        memberId: 'ibu',
        capturedAt: DateTime(2026, 9, 1),
        createdAt: 1,
      ),
    );

    await members.insert(member.copyWith(name: 'Mama'));

    expect((await moments.getAll()).single.memberId, 'ibu');
    expect((await members.getAll()).single.name, 'Mama');
  });

  test(
    'full memory reads contain records past old 50 and 500 limits',
    () async {
      final db = await database.database;
      final batch = db.batch();
      for (var index = 0; index < 521; index++) {
        batch.insert(
          'moments',
          Moment(
            id: 'memory-$index',
            title: 'Momen $index',
            note: 'Catatan',
            capturedAt: DateTime(2025, 1, 1).add(Duration(days: index)),
            createdAt: index,
          ).toMap(),
        );
      }
      await batch.commit(noResult: true);

      expect(await moments.getAll(), hasLength(521));
      expect(await moments.getRecent(), hasLength(521));
      expect(await moments.getRecent(limit: 20), hasLength(20));
    },
  );

  test('full completion read contains records past old 100 limit', () async {
    await rituals.save(Ritual(id: 'reading', title: 'Baca', createdAt: 1));
    final db = await database.database;
    final batch = db.batch();
    for (var index = 0; index < 121; index++) {
      batch.insert('ritual_checkins', {
        'ritual_id': 'reading',
        'day_key': ritualDayKey(
          DateTime(2026, 1, 1).add(Duration(days: index)),
        ),
        'completed_at': index,
      });
    }
    await batch.commit(noResult: true);

    expect(await rituals.getCheckIns(), hasLength(121));
  });

  test('deleting a member keeps their memories without association', () async {
    await members.insert(FamilyMember(id: 'ibu', name: 'Ibu', createdAt: 1));
    await moments.save(
      Moment(
        id: 'memory',
        title: 'Hari ini',
        note: 'Tetap tersimpan.',
        memberId: 'ibu',
        capturedAt: DateTime(2026, 9, 1),
        createdAt: 1,
      ),
    );

    await members.delete('ibu');

    final remaining = await moments.getAll();
    expect(remaining, hasLength(1));
    expect(remaining.single.memberId, isNull);
  });

  test('archive and restore retain completion history', () async {
    await rituals.save(Ritual(id: 'reading', title: 'Baca', createdAt: 1));
    await rituals.setCheckIn('reading', DateTime(2026, 9, 1), true);
    await rituals.archive('reading');
    expect(await rituals.getAll(), isEmpty);
    expect(
      (await rituals.getAll(includeArchived: true)).single.isArchived,
      isTrue,
    );

    await rituals.restore('reading');

    expect((await rituals.getAll()).single.isArchived, isFalse);
    expect(await rituals.getCompletedIdsFor(DateTime(2026, 9, 1)), {'reading'});
  });

  test(
    'paged search treats wildcard text literally and applies mood filter',
    () async {
      for (var index = 0; index < 4; index++) {
        await moments.save(
          Moment(
            id: 'memory-$index',
            title: index < 3 ? '100% senang' : '1000 senang',
            note: 'Catatan',
            tag: index == 0 ? MomentTag.learn : MomentTag.laugh,
            capturedAt: DateTime(2026, 9, 1),
            createdAt: index,
          ),
        );
      }

      final first = await moments.getPage(
        limit: 1,
        query: '100%',
        tag: MomentTag.laugh,
      );
      final second = await moments.getPage(
        limit: 1,
        offset: 1,
        query: '100%',
        tag: MomentTag.laugh,
      );

      expect(first.single.id, 'memory-2');
      expect(second.single.id, 'memory-1');
    },
  );
}
