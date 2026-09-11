import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Owns permanent, private journal photos independently of picker cache files.
class JournalMediaStore {
  JournalMediaStore({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectory;
  static const maxPhotoBytes = 20 * 1024 * 1024;
  static const maxPhotoPixels = 24 * 1000 * 1000;

  Future<Directory> _directory() async =>
      Directory(p.join((await _documentsDirectory()).path, 'journal_media'));

  Future<String> persistPhoto(String sourcePath) async {
    final bytes = await readPhotoBytes(sourcePath);
    final source = await File(sourcePath).resolveSymbolicLinks();
    final directory = await _directory();
    if (await directory.exists()) {
      final managed = await directory.resolveSymbolicLinks();
      if (p.isWithin(managed, source)) return source;
    }
    return savePhotoBytes(bytes);
  }

  /// Always chooses its own filename. Backup identifiers never become paths.
  Future<String> savePhotoBytes(Uint8List bytes) async {
    final extension = await compute(validatePhoto, bytes);
    final directory = await _directory();
    await directory.create(recursive: true);
    final file = File(
      p.join(directory.path, '${const Uuid().v4()}.$extension'),
    );
    try {
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<Uint8List> readPhotoBytes(String path) async {
    final file = File(path);
    if (await file.length() > maxPhotoBytes) {
      throw const FormatException(
        'Foto terlalu besar. Maksimal 20 MB per foto.',
      );
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (builder.length + chunk.length > maxPhotoBytes) {
        throw const FormatException(
          'Foto terlalu besar. Maksimal 20 MB per foto.',
        );
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    await compute(validatePhoto, bytes);
    return bytes;
  }

  /// Used to roll back files created by a failed import, never external photos.
  Future<void> deleteManagedPhoto(String path) async {
    final directory = await _directory();
    final absolute = p.normalize(p.absolute(path));
    if (!p.isWithin(p.normalize(p.absolute(directory.path)), absolute)) {
      throw ArgumentError.value(path, 'path', 'Bukan foto milik jurnal.');
    }
    final file = File(absolute);
    if (!await file.exists()) return;
    if (!p.isWithin(
      await directory.resolveSymbolicLinks(),
      await file.resolveSymbolicLinks(),
    )) {
      throw ArgumentError.value(path, 'path', 'Bukan foto milik jurnal.');
    }
    await file.delete();
  }

  /// Limits both encoded bytes and decoded pixels before allocating an image.
  static String validatePhoto(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxPhotoBytes) {
      throw const FormatException('Foto kosong atau melebihi batas 20 MB.');
    }
    try {
      final decoders = <img.Decoder>[
        img.JpegDecoder(),
        img.PngDecoder(),
        img.WebPDecoder(),
        img.GifDecoder(),
      ];
      final decoder = decoders
          .where((item) => item.isValidFile(bytes))
          .firstOrNull;
      final info = decoder?.startDecode(bytes);
      if (info == null ||
          info.width <= 0 ||
          info.height <= 0 ||
          info.width > 12000 ||
          info.height > 12000 ||
          info.width * info.height > maxPhotoPixels ||
          info.numFrames > 200 ||
          decoder!.decodeFrame(0) == null) {
        throw const FormatException(
          'Foto tidak valid atau resolusinya terlalu besar.',
        );
      }
      return decoder.format.name;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Gunakan foto JPEG, PNG, WebP, atau GIF yang valid.',
      );
    }
  }
}
