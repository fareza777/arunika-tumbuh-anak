import 'dart:async';
import 'dart:io';

import 'package:arunika_growth/data/db/app_database.dart';
import 'package:arunika_growth/data/models/family_member.dart';
import 'package:arunika_growth/data/models/moment.dart';
import 'package:arunika_growth/data/models/ritual.dart';
import 'package:arunika_growth/data/repo/family_member_repository.dart';
import 'package:arunika_growth/data/repo/moment_repository.dart';
import 'package:arunika_growth/data/repo/ritual_repository.dart';
import 'package:arunika_growth/domain/together/journal_media_store.dart';
import 'package:arunika_growth/state/together_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late MomentRepository moments;
  late FamilyMemberRepository members;
  late RitualRepository rituals;
  late JournalMediaStore media;
  late ProviderContainer container;
  late TogetherActions actions;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('arunika-actions-');
    database = AppDatabase(
      path: p.join(directory.path, 'journal.db'),
      factory: databaseFactoryFfi,
    );
    moments = MomentRepository(database: database);
    members = FamilyMemberRepository(database: database);
    rituals = RitualRepository(database: database);
    media = JournalMediaStore(
      documentsDirectory: () async => Directory(p.join(directory.path, 'app')),
    );
    container = ProviderContainer(
      overrides: [
        momentRepositoryProvider.overrideWithValue(moments),
        familyMemberRepositoryProvider.overrideWithValue(members),
        ritualRepositoryProvider.overrideWithValue(rituals),
        journalMediaStoreProvider.overrideWithValue(media),
      ],
    );
    actions = container.read(togetherActionsProvider);
  });
  tearDown(() async {
    container.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  Moment memory(String id, String? photo) => Moment(
    id: id,
    title: 'Hari yang hangat',
    note: 'Baca buku bersama.',
    photoPath: photo,
    capturedAt: DateTime(2026, 9, 1),
    createdAt: 1,
  );

  Future<File> pickerPhoto([String name = 'picker.png']) async {
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(img.encodePng(img.Image(width: 2, height: 2)));
    return file;
  }

  Future<List<FileSystemEntity>> managedPhotos() async {
    final folder = Directory(p.join(directory.path, 'app', 'journal_media'));
    return await folder.exists() ? folder.list().toList() : [];
  }

  test('failed database save removes only its new photo copy', () async {
    final original = await pickerPhoto();
    final db = await database.database;
    await db.execute(
      "CREATE TRIGGER reject_save BEFORE INSERT ON moments BEGIN SELECT RAISE(ABORT, 'disk unavailable'); END",
    );

    await expectLater(
      actions.saveMoment(memory('m', original.path)),
      throwsA(isA<DatabaseException>()),
    );

    expect(await moments.getAll(), isEmpty);
    expect(await managedPhotos(), isEmpty);
    expect(await original.exists(), isTrue);
    await db.execute('DROP TRIGGER reject_save');
    await actions.saveMoment(memory('m', original.path));
    expect(await moments.getAll(), hasLength(1));
    expect(await managedPhotos(), hasLength(1));
  });

  test(
    'replacement removes unused managed photo but preserves picker original',
    () async {
      final original = await pickerPhoto();
      final oldPhoto = await media.savePhotoBytes(await original.readAsBytes());
      final initial = memory('m', oldPhoto);
      await moments.save(initial);

      await actions.saveMoment(initial.copyWith(photoPath: original.path));

      final saved = (await moments.getAll()).single;
      expect(await File(oldPhoto).exists(), isFalse);
      expect(saved.photoPath, isNot(original.path));
      expect(await File(saved.photoPath!).exists(), isTrue);
      expect(await original.exists(), isTrue);
      expect(await managedPhotos(), hasLength(1));
    },
  );

  test(
    'shared photo remains until the last memory and member reference is gone',
    () async {
      final original = await pickerPhoto();
      final photo = await media.savePhotoBytes(await original.readAsBytes());
      await moments.save(memory('first', photo));
      await moments.save(memory('second', photo));
      await members.insert(
        FamilyMember(id: 'ibu', name: 'Ibu', photoPath: photo, createdAt: 1),
      );

      await actions.deleteMoment('first');
      expect(await File(photo).exists(), isTrue);
      await actions.deleteMoment('second');
      expect(await File(photo).exists(), isTrue);
      await actions.deleteMember('ibu');

      expect(await File(photo).exists(), isFalse);
      expect(await original.exists(), isTrue);
    },
  );

  test(
    'deleting a legacy memory never deletes its original gallery file',
    () async {
      final original = await pickerPhoto();
      await moments.save(memory('legacy', original.path));

      await actions.deleteMoment('legacy');

      expect(await moments.getAll(), isEmpty);
      expect(await original.exists(), isTrue);
    },
  );

  test(
    'text edits retain a previously unavailable photo without blocking save',
    () async {
      final lostPhoto = p.join(
        directory.path,
        'app',
        'journal_media',
        'lost.png',
      );
      final initial = memory('legacy', lostPhoto);
      await moments.save(initial);

      await actions.saveMoment(
        initial.copyWith(note: 'Catatan sudah diperbaiki.'),
      );

      final saved = (await moments.getAll()).single;
      expect(saved.note, 'Catatan sudah diperbaiki.');
      expect(saved.photoPath, lostPhoto);
    },
  );

  test(
    'save and delete are serialized so a late save cannot resurrect a memory',
    () async {
      final original = await pickerPhoto();
      final photo = await media.savePhotoBytes(await original.readAsBytes());
      final initial = memory('m', photo);
      await moments.save(initial);
      final gated = _GatedMomentRepository(database: database);
      container.dispose();
      container = ProviderContainer(
        overrides: [
          momentRepositoryProvider.overrideWithValue(gated),
          familyMemberRepositoryProvider.overrideWithValue(members),
          ritualRepositoryProvider.overrideWithValue(rituals),
          journalMediaStoreProvider.overrideWithValue(media),
        ],
      );
      actions = container.read(togetherActionsProvider);

      final save = actions.saveMoment(initial.copyWith(note: 'Diperbarui'));
      await gated.started.future;
      final deletion = actions.deleteMoment('m');
      gated.release.complete();
      await Future.wait([save, deletion]);

      expect(gated.events, [
        'save started',
        'save committed',
        'delete started',
        'delete committed',
      ]);
      expect(await moments.getAll(), isEmpty);
      expect(await File(photo).exists(), isFalse);
    },
  );

  test(
    'failed starter creation rolls back and a retry creates the complete set',
    () async {
      final db = await database.database;
      await db.execute(
        "CREATE TRIGGER reject_second_starter BEFORE INSERT ON rituals WHEN NEW.title = 'Tiga hal yang disyukuri' BEGIN SELECT RAISE(ABORT, 'disk unavailable'); END",
      );

      await expectLater(
        actions.seedStarterRituals(),
        throwsA(isA<DatabaseException>()),
      );

      expect(await rituals.getAll(includeArchived: true), isEmpty);
      await db.execute('DROP TRIGGER reject_second_starter');
      await actions.seedStarterRituals();
      await actions.seedStarterRituals();
      expect(
        (await rituals.getAll()).map((item) => item.title),
        unorderedEquals([
          'Cerita sebelum tidur',
          'Tiga hal yang disyukuri',
          'Jalan sebentar',
        ]),
      );
    },
  );

  test(
    'retry repairs an old partial starter set and preserves archived customization',
    () async {
      await rituals.save(
        Ritual(
          id: 'old-random-id',
          title: 'Cerita sebelum tidur',
          description: 'Disesuaikan keluarga',
          isArchived: true,
          createdAt: 1,
        ),
      );

      await actions.seedStarterRituals();
      await actions.seedStarterRituals();

      final all = await rituals.getAll(includeArchived: true);
      expect(all, hasLength(3));
      final existing = all.firstWhere((item) => item.id == 'old-random-id');
      expect(existing.description, 'Disesuaikan keluarga');
      expect(existing.isArchived, isTrue);
    },
  );

  test('failed deletion keeps both the memory and its managed photo', () async {
    final original = await pickerPhoto();
    final photo = await media.savePhotoBytes(await original.readAsBytes());
    await moments.save(memory('m', photo));
    final db = await database.database;
    await db.execute(
      "CREATE TRIGGER reject_delete BEFORE DELETE ON moments BEGIN SELECT RAISE(ABORT, 'disk unavailable'); END",
    );

    await expectLater(
      actions.deleteMoment('m'),
      throwsA(isA<DatabaseException>()),
    );

    expect(await moments.getAll(), hasLength(1));
    expect(await File(photo).exists(), isTrue);
    expect(container.read(journalStorageWarningProvider), isNull);
  });

  test('failed save never erases an already existing managed image', () async {
    final original = await pickerPhoto();
    final photo = await media.savePhotoBytes(await original.readAsBytes());
    final db = await database.database;
    await db.execute(
      "CREATE TRIGGER reject_save BEFORE INSERT ON moments BEGIN SELECT RAISE(ABORT, 'disk unavailable'); END",
    );

    await expectLater(
      actions.saveMoment(memory('m', photo)),
      throwsA(isA<DatabaseException>()),
    );

    expect(await File(photo).exists(), isTrue);
    expect(await managedPhotos(), hasLength(1));
  });

  test(
    'cleanup failure reports a warning without undoing a committed deletion',
    () async {
      final original = await pickerPhoto();
      final photo = await media.savePhotoBytes(await original.readAsBytes());
      await moments.save(memory('m', photo));
      final failingMedia = _DeletionFailureMediaStore(
        documentsDirectory: () async =>
            Directory(p.join(directory.path, 'app')),
      );
      container.dispose();
      container = ProviderContainer(
        overrides: [
          momentRepositoryProvider.overrideWithValue(moments),
          familyMemberRepositoryProvider.overrideWithValue(members),
          ritualRepositoryProvider.overrideWithValue(rituals),
          journalMediaStoreProvider.overrideWithValue(failingMedia),
        ],
      );
      actions = container.read(togetherActionsProvider);

      await actions.deleteMoment('m');

      expect(await moments.getAll(), isEmpty);
      expect(await File(photo).exists(), isTrue);
      expect(container.read(journalStorageWarningProvider), isNotEmpty);
    },
  );

  test('successful writes refresh the visible moments provider', () async {
    expect(await container.read(momentsProvider.future), isEmpty);

    await actions.saveMoment(memory('m', null));

    expect((await container.read(momentsProvider.future)).single.id, 'm');
    await actions.deleteMoment('m');
    expect(await container.read(momentsProvider.future), isEmpty);
  });

  test(
    'retrying a stable member identifier preserves photo and creation date',
    () async {
      final original = await pickerPhoto();
      final photo = await media.savePhotoBytes(await original.readAsBytes());
      await members.insert(
        FamilyMember(id: 'ibu', name: 'Ibu', photoPath: photo, createdAt: 7),
      );

      await actions.addMember(id: 'ibu', name: 'Mama', role: 'parent');

      final saved = (await members.getAll()).single;
      expect(saved.name, 'Mama');
      expect(saved.photoPath, photo);
      expect(saved.createdAt, 7);
    },
  );
}

class _GatedMomentRepository extends MomentRepository {
  _GatedMomentRepository({required super.database});
  final started = Completer<void>();
  final release = Completer<void>();
  final events = <String>[];

  @override
  Future<void> save(Moment moment) async {
    events.add('save started');
    started.complete();
    await release.future;
    await super.save(moment);
    events.add('save committed');
  }

  @override
  Future<void> delete(String id) async {
    events.add('delete started');
    await super.delete(id);
    events.add('delete committed');
  }
}

class _DeletionFailureMediaStore extends JournalMediaStore {
  _DeletionFailureMediaStore({required super.documentsDirectory});

  @override
  Future<void> deleteManagedPhoto(String path) async {
    throw FileSystemException('Photo storage is unavailable', path);
  }
}
