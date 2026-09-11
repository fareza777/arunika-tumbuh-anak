import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:arunika_growth/domain/together/journal_media_store.dart';

void main() {
  late Directory directory;
  late JournalMediaStore store;
  late Uint8List photo;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('arunika-media-');
    store = JournalMediaStore(documentsDirectory: () async => directory);
    photo = img.encodePng(img.Image(width: 2, height: 2));
  });

  tearDown(() => directory.delete(recursive: true));

  test('selected cache photo survives removal of the picker file', () async {
    final original = File(p.join(directory.path, 'picker.tmp'));
    await original.writeAsBytes(photo);

    final path = await store.persistPhoto(original.path);
    await original.delete();

    expect(p.isWithin(p.join(directory.path, 'journal_media'), path), isTrue);
    expect(await File(path).readAsBytes(), photo);
    expect(p.extension(path), '.png');
  });

  test('resaving a managed photo does not create additional copies', () async {
    final path = await store.savePhotoBytes(photo);

    expect(await store.persistPhoto(path), path);
    expect(await Directory(p.dirname(path)).list().length, 1);
  });

  test(
    'invalid and oversized image bytes are rejected before writing',
    () async {
      await expectLater(
        store.savePhotoBytes(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
      await expectLater(
        store.savePhotoBytes(Uint8List(JournalMediaStore.maxPhotoBytes + 1)),
        throwsFormatException,
      );

      expect(await directory.list().length, 0);
    },
  );

  test('cleanup refuses files outside the managed media directory', () async {
    final original = File(p.join(directory.path, 'keep.png'));
    await original.writeAsBytes(photo);

    await expectLater(
      store.deleteManagedPhoto(original.path),
      throwsArgumentError,
    );

    expect(await original.exists(), isTrue);
  });

  test(
    'excessive decoded image dimensions reject even a small encoded file',
    () async {
      final widePhoto = img.encodePng(img.Image(width: 13001, height: 1));

      await expectLater(store.savePhotoBytes(widePhoto), throwsFormatException);

      expect(await directory.list().length, 0);
    },
  );
}
