import 'dart:convert';
import 'dart:io';

import 'package:arunika_growth/data/db/app_database.dart';
import 'package:arunika_growth/data/models/family_member.dart';
import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/data/models/ritual.dart';
import 'package:arunika_growth/data/repo/family_member_repository.dart';
import 'package:arunika_growth/data/repo/moment_repository.dart';
import 'package:arunika_growth/data/repo/ritual_repository.dart';
import 'package:arunika_growth/domain/together/journal_backup_service.dart';
import 'package:arunika_growth/domain/together/journal_media_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late AppDatabase source;
  late AppDatabase target;
  late JournalMediaStore sourceMedia;
  late JournalMediaStore targetMedia;
  late JournalBackupService exporter;
  late JournalBackupService importer;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('arunika-backup-');
    source = AppDatabase(
      path: p.join(directory.path, 'source.db'),
      factory: databaseFactoryFfi,
    );
    target = AppDatabase(
      path: p.join(directory.path, 'target.db'),
      factory: databaseFactoryFfi,
    );
    sourceMedia = JournalMediaStore(
      documentsDirectory: () async =>
          Directory(p.join(directory.path, 'source')),
    );
    targetMedia = JournalMediaStore(
      documentsDirectory: () async =>
          Directory(p.join(directory.path, 'target')),
    );
    exporter = JournalBackupService(
      database: source,
      mediaStore: sourceMedia,
      temporaryDirectory: () async => directory,
    );
    importer = JournalBackupService(
      database: target,
      mediaStore: targetMedia,
      temporaryDirectory: () async => directory,
    );
  });
  tearDown(() async {
    await source.close();
    await target.close();
    await directory.delete(recursive: true);
  });

  Future<String> seed({int momentCount = 1, int checkInCount = 1}) async {
    final photo = await sourceMedia.savePhotoBytes(
      img.encodePng(img.Image(width: 2, height: 2)),
    );
    await FamilyMemberRepository(database: source).insert(
      FamilyMember(id: 'ibu', name: 'Ibu', photoPath: photo, createdAt: 1),
    );
    await RitualRepository(database: source).save(
      Ritual(
        id: 'reading',
        title: 'Baca bersama',
        isArchived: true,
        createdAt: 1,
      ),
    );
    final db = await source.database;
    final batch = db.batch();
    for (var index = 0; index < momentCount; index++) {
      batch.insert(
        'moments',
        Moment(
          id: 'memory-$index',
          title: 'Momen $index',
          note: 'Catatan utuh $index',
          memberId: 'ibu',
          photoPath: index == 0 ? photo : null,
          capturedAt: DateTime(2025, 1, 1).add(Duration(days: index)),
          createdAt: index,
        ).toMap(),
      );
    }
    for (var index = 0; index < checkInCount; index++) {
      batch.insert('ritual_checkins', {
        'ritual_id': 'reading',
        'day_key': ritualDayKey(
          DateTime(2025, 1, 1).add(Duration(days: index)),
        ),
        'completed_at': DateTime(
          2025,
          1,
          1,
        ).add(Duration(days: index)).millisecondsSinceEpoch,
      });
    }
    await batch.commit(noResult: true);
    return photo;
  }

  Future<File> mutate(void Function(Map<String, dynamic>) change) async {
    final file = await exporter.exportToFile(familyName: 'Keluarga Awan');
    final payload =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    change(payload);
    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  test(
    'round trip includes all rows, archives and shared photos past old limits',
    () async {
      final originalPhoto = await seed(momentCount: 521, checkInCount: 121);
      final file = await exporter.exportToFile(familyName: 'Keluarga Awan');
      expect(await file.readAsString(), isNot(contains(originalPhoto)));

      final result = await importer.importFromFile(file.path);

      expect(result.membersAdded, 1);
      expect(result.ritualsAdded, 1);
      expect(result.checkInsAdded, 121);
      expect(result.momentsAdded, 521);
      expect(result.photosAdded, 1);
      expect(result.familyName, 'Keluarga Awan');
      expect(
        (await RitualRepository(
          database: target,
        ).getAll(includeArchived: true)).single.isArchived,
        isTrue,
      );
      final member = (await FamilyMemberRepository(
        database: target,
      ).getAll()).single;
      final memory = (await MomentRepository(
        database: target,
      ).getAll()).firstWhere((item) => item.id == 'memory-0');
      expect(memory.photoPath, member.photoPath);
      expect(memory.memberId, 'ibu');
      expect(
        await File(memory.photoPath!).readAsBytes(),
        await File(originalPhoto).readAsBytes(),
      );

      final repeated = await importer.importFromFile(file.path);
      expect(repeated.totalAdded, 0);
      expect(repeated.duplicatesSkipped, 644);
      expect(repeated.photosAdded, 0);
      expect(await Directory(p.dirname(memory.photoPath!)).list().length, 1);
    },
  );

  test(
    'merge skips duplicate identifiers without overwriting local content',
    () async {
      await seed();
      await FamilyMemberRepository(
        database: target,
      ).insert(FamilyMember(id: 'ibu', name: 'Mama lokal', createdAt: 9));
      await RitualRepository(
        database: target,
      ).save(Ritual(id: 'reading', title: 'Ritual lokal', createdAt: 9));
      await MomentRepository(database: target).save(
        Moment(
          id: 'memory-0',
          title: 'Momen lokal',
          note: 'Jangan ditimpa',
          capturedAt: DateTime(2026, 9, 1),
          createdAt: 9,
        ),
      );
      final file = await exporter.exportToFile();

      final result = await importer.importFromFile(file.path);

      expect(result.duplicatesSkipped, 3);
      expect(result.checkInsAdded, 1);
      expect(result.photosAdded, 0);
      expect(
        (await FamilyMemberRepository(database: target).getAll()).single.name,
        'Mama lokal',
      );
      expect(
        (await RitualRepository(database: target).getAll()).single.title,
        'Ritual lokal',
      );
      expect(
        (await MomentRepository(database: target).getAll()).single.note,
        'Jangan ditimpa',
      );
    },
  );

  test(
    'invalid final row is rejected before any row or photo is restored',
    () async {
      await seed(momentCount: 2);
      final file = await mutate(
        (payload) => payload['moments'][1]['captured_at'] = 'invalid',
      );

      await expectLater(
        importer.importFromFile(file.path),
        throwsFormatException,
      );

      expect(await FamilyMemberRepository(database: target).getAll(), isEmpty);
      expect(
        await RitualRepository(database: target).getAll(includeArchived: true),
        isEmpty,
      );
      expect(
        await Directory(p.join(directory.path, 'target')).exists(),
        isFalse,
      );
    },
  );

  test(
    'unsupported versions and traversal media references are rejected',
    () async {
      await seed();
      var file = await mutate((payload) => payload['format'] = 999);
      await expectLater(
        importer.importFromFile(file.path),
        throwsFormatException,
      );
      file = await mutate(
        (payload) => payload['moments'][0]['photo_path'] = '../outside.jpg',
      );
      await expectLater(
        importer.importFromFile(file.path),
        throwsFormatException,
      );
      expect(await MomentRepository(database: target).getAll(), isEmpty);
    },
  );

  test(
    'database failure rolls back new rows and photos and preserves legacy data',
    () async {
      await seed();
      final db = await target.database;
      await db.insert('children', {
        'id': 'legacy',
        'name': 'Catatan lama',
        'gender': 'female',
        'birth_date': 1,
        'created_at': 1,
      });
      await db.execute(
        "CREATE TRIGGER reject_import BEFORE INSERT ON moments BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      final file = await exporter.exportToFile();

      await expectLater(
        importer.importFromFile(file.path),
        throwsA(isA<DatabaseException>()),
      );

      expect(await db.query('family_members'), isEmpty);
      expect(await db.query('rituals'), isEmpty);
      expect((await db.query('children')).single['name'], 'Catatan lama');
      final mediaDirectory = Directory(
        p.join(directory.path, 'target', 'journal_media'),
      );
      expect(await mediaDirectory.list().length, 0);
    },
  );

  test(
    'unavailable legacy photo is explicitly reported and text survives',
    () async {
      final photo = await seed();
      await File(photo).delete();
      var missing = 0;
      final file = await exporter.exportToFile(
        onMissingPhotos: (count) => missing = count,
      );

      final result = await importer.importFromFile(file.path);

      expect(missing, 1);
      expect(result.missingPhotos, 1);
      expect(
        (await MomentRepository(database: target).getAll()).single.note,
        'Catatan utuh 0',
      );
      expect(
        (await MomentRepository(database: target).getAll()).single.photoPath,
        isNull,
      );
    },
  );

  test('broken media payload rejects the complete import', () async {
    await seed();
    final file = await mutate(
      (payload) => payload['media'][0]['data'] = base64Encode([1, 2, 3]),
    );

    await expectLater(
      importer.importFromFile(file.path),
      throwsFormatException,
    );

    expect(await MomentRepository(database: target).getAll(), isEmpty);
    expect(await FamilyMemberRepository(database: target).getAll(), isEmpty);
  });

  test(
    'fractional version values are not treated as an integer format version',
    () async {
      await seed();
      final file = await mutate((payload) => payload['format'] = 1.0);

      await expectLater(
        importer.importFromFile(file.path),
        throwsFormatException,
      );

      expect(await MomentRepository(database: target).getAll(), isEmpty);
    },
  );

  test(
    'oversized record collections reject before processing row values',
    () async {
      final file = await mutate(
        (payload) => payload['moments'] = List.filled(
          JournalBackupService.maxRecords + 1,
          <String, Object?>{},
        ),
      );

      await expectLater(
        importer.importFromFile(file.path),
        throwsFormatException,
      );

      expect(await MomentRepository(database: target).getAll(), isEmpty);
    },
  );
}
