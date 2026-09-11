import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/models/moment.dart';
import '../../data/models/ritual.dart';
import 'journal_media_store.dart';

class JournalImportSummary {
  const JournalImportSummary({
    required this.membersAdded,
    required this.ritualsAdded,
    required this.checkInsAdded,
    required this.momentsAdded,
    required this.photosAdded,
    required this.duplicatesSkipped,
    required this.missingPhotos,
    required this.familyName,
  });

  final int membersAdded;
  final int ritualsAdded;
  final int checkInsAdded;
  final int momentsAdded;
  final int photosAdded;
  final int duplicatesSkipped;

  /// Photos already unavailable on the device that created the backup.
  final int missingPhotos;
  final String familyName;
  int get totalAdded =>
      membersAdded + ritualsAdded + checkInsAdded + momentsAdded;
}

/// A self-contained, versioned backup of the active offline family journal.
/// Existing rows are never replaced. Legacy tables are never written here.
class JournalBackupService {
  JournalBackupService({
    AppDatabase? database,
    JournalMediaStore? mediaStore,
    Future<Directory> Function()? temporaryDirectory,
  }) : _database = database ?? AppDatabase.instance,
       _mediaStore = mediaStore ?? JournalMediaStore(),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final AppDatabase _database;
  final JournalMediaStore _mediaStore;
  final Future<Directory> Function() _temporaryDirectory;
  static const maxBackupBytes = 256 * 1024 * 1024;
  static const maxMediaBytes = 128 * 1024 * 1024;
  static const maxRecords = 100000;
  static const _tables = [
    'family_members',
    'rituals',
    'ritual_checkins',
    'moments',
  ];

  Future<File> exportToFile({
    String familyName = 'Keluarga',
    void Function(int missingPhotos)? onMissingPhotos,
  }) async {
    final db = await _database.database;
    // Read all four tables in one snapshot, including archived habits.
    final tables = await db.transaction((txn) async {
      final result = <String, List<Map<String, Object?>>>{};
      for (final table in _tables) {
        result[table] = (await txn.query(
          table,
        )).map(Map<String, Object?>.of).toList();
      }
      return result;
    });
    if (tables.values.fold<int>(0, (count, rows) => count + rows.length) >
        maxRecords) {
      throw const FormatException(
        'Jurnal melebihi batas 100.000 catatan per cadangan.',
      );
    }
    final media = <Map<String, Object?>>[];
    final photoIds = <String, String?>{};
    var mediaBytes = 0;
    var missingPhotos = 0;
    for (final table in ['family_members', 'moments']) {
      for (final row in tables[table]!) {
        final path = row['photo_path'] as String?;
        if (path == null || path.isEmpty) {
          row['photo_path'] = null;
          continue;
        }
        if (!photoIds.containsKey(path)) {
          Uint8List? bytes;
          try {
            bytes = await _mediaStore.readPhotoBytes(path);
          } on FileSystemException {
            missingPhotos++;
          } on FormatException {
            missingPhotos++;
          }
          if (bytes == null) {
            photoIds[path] = null;
          } else {
            mediaBytes += bytes.length;
            if (mediaBytes > maxMediaBytes) {
              throw const FormatException(
                'Foto melebihi batas 128 MB per cadangan.',
              );
            }
            final id = 'photo-${media.length + 1}';
            photoIds[path] = id;
            media.add({'id': id, 'data': base64Encode(bytes)});
          }
        }
        row['photo_path'] = photoIds[path];
      }
    }
    final payload = <String, Object?>{
      'app': 'id.arunika.arunika_growth',
      'kind': 'family-journal',
      'format': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'family_name': familyName,
      'missing_photos': missingPhotos,
      ...tables,
      'media': media,
    };
    final encoded = await compute(_encodeBackup, payload);
    final directory = await _temporaryDirectory();
    await directory.create(recursive: true);
    final file = File(
      p.join(directory.path, 'arunika-jurnal-${const Uuid().v4()}.json'),
    );
    try {
      await file.writeAsBytes(encoded, flush: true);
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    }
    onMissingPhotos?.call(missingPhotos);
    return file;
  }

  Future<JournalImportSummary> importFromFile(String path) async {
    final file = File(path);
    if (await file.length() > maxBackupBytes) {
      throw const FormatException('Cadangan melebihi batas 256 MB.');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (builder.length + chunk.length > maxBackupBytes) {
        throw const FormatException('Cadangan melebihi batas 256 MB.');
      }
      builder.add(chunk);
    }
    // Validate every row and image before any database or media mutation.
    final payload = await compute(_decodeBackup, builder.takeBytes());
    final db = await _database.database;
    final createdPhotos = <String>[];
    try {
      return await db.transaction((txn) async {
        final additions = <String, List<Map<String, Object?>>>{};
        var duplicates = 0;
        for (final table in _tables) {
          final existing = (await txn.query(
            table,
          )).map((row) => _rowKey(table, row)).toSet();
          additions[table] = [];
          for (final row in payload.tables[table]!) {
            if (existing.contains(_rowKey(table, row))) {
              duplicates++;
            } else {
              additions[table]!.add(Map<String, Object?>.of(row));
            }
          }
        }
        await _validateReferences(txn, additions);
        final photoPaths = <String, String>{};
        for (final table in ['family_members', 'moments']) {
          for (final row in additions[table]!) {
            final id = row['photo_path'] as String?;
            if (id == null) continue;
            if (!photoPaths.containsKey(id)) {
              final stored = await _mediaStore.savePhotoBytes(
                payload.media[id]!,
              );
              createdPhotos.add(stored);
              photoPaths[id] = stored;
            }
            row['photo_path'] = photoPaths[id];
          }
        }
        for (final table in _tables) {
          final batch = txn.batch();
          for (final row in additions[table]!) {
            batch.insert(table, row);
          }
          await batch.commit(noResult: true);
        }
        return JournalImportSummary(
          membersAdded: additions['family_members']!.length,
          ritualsAdded: additions['rituals']!.length,
          checkInsAdded: additions['ritual_checkins']!.length,
          momentsAdded: additions['moments']!.length,
          photosAdded: createdPhotos.length,
          duplicatesSkipped: duplicates,
          missingPhotos: payload.missingPhotos,
          familyName: payload.familyName,
        );
      });
    } catch (_) {
      // Only our newly generated paths are cleaned up after the DB rolls back.
      for (final photo in createdPhotos) {
        try {
          await _mediaStore.deleteManagedPhoto(photo);
        } on FileSystemException {
          // An orphan image is harmless; preserve the original import error.
        }
      }
      rethrow;
    }
  }

  Future<void> _validateReferences(
    DatabaseExecutor db,
    Map<String, List<Map<String, Object?>>> additions,
  ) async {
    final memberIds =
        (await db.query(
            'family_members',
            columns: ['id'],
          )).map((row) => row['id']).toSet()
          ..addAll(additions['family_members']!.map((row) => row['id']));
    final ritualIds =
        (await db.query(
            'rituals',
            columns: ['id'],
          )).map((row) => row['id']).toSet()
          ..addAll(additions['rituals']!.map((row) => row['id']));
    for (final row in additions['moments']!) {
      if (row['member_id'] != null && !memberIds.contains(row['member_id'])) {
        throw const FormatException(
          'Hubungan anggota keluarga dalam cadangan tidak lengkap.',
        );
      }
    }
    for (final row in additions['ritual_checkins']!) {
      if (!ritualIds.contains(row['ritual_id'])) {
        throw const FormatException(
          'Riwayat kebiasaan dalam cadangan tidak lengkap.',
        );
      }
    }
  }
}

String _rowKey(String table, Map<String, Object?> row) =>
    table == 'ritual_checkins'
    ? jsonEncode([row['ritual_id'], row['day_key']])
    : row['id']! as String;

Uint8List _encodeBackup(Map<String, Object?> payload) {
  final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  if (bytes.length > JournalBackupService.maxBackupBytes) {
    throw const FormatException('Cadangan melebihi batas 256 MB.');
  }
  // The exporter and importer share one contract, preventing unrestorable files.
  _decodeBackup(bytes);
  return bytes;
}

class _BackupPayload {
  const _BackupPayload(
    this.tables,
    this.media,
    this.familyName,
    this.missingPhotos,
  );
  final Map<String, List<Map<String, Object?>>> tables;
  final Map<String, Uint8List> media;
  final String familyName;
  final int missingPhotos;
}

_BackupPayload _decodeBackup(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > JournalBackupService.maxBackupBytes) {
    throw const FormatException('Ukuran cadangan tidak valid.');
  }
  final dynamic decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } catch (_) {
    throw const FormatException('Berkas bukan JSON cadangan yang valid.');
  }
  if (decoded is! Map<String, dynamic> ||
      decoded['app'] != 'id.arunika.arunika_growth' ||
      decoded['kind'] != 'family-journal' ||
      decoded['format'] is! int ||
      decoded['format'] != 1) {
    throw const FormatException(
      'Format atau versi cadangan jurnal tidak didukung.',
    );
  }
  final familyName = _text(decoded, 'family_name', max: 120);
  final exportedAt = _text(decoded, 'exported_at', max: 40);
  if (DateTime.tryParse(exportedAt) == null) {
    throw const FormatException('Tanggal cadangan tidak valid.');
  }
  final missingPhotos = _integer(
    decoded,
    'missing_photos',
    min: 0,
    max: JournalBackupService.maxRecords,
  );
  var records = 0;
  final tables = <String, List<Map<String, Object?>>>{};
  for (final table in JournalBackupService._tables) {
    final rawRows = decoded[table];
    if (rawRows is! List) throw FormatException('Bagian $table tidak lengkap.');
    records += rawRows.length;
    if (records > JournalBackupService.maxRecords) {
      throw const FormatException('Cadangan melebihi batas 100.000 catatan.');
    }
    final seen = <String>{};
    tables[table] = rawRows.map((raw) {
      if (raw is! Map<String, dynamic>) {
        throw FormatException('Catatan $table tidak valid.');
      }
      final row = _validateRow(table, raw);
      if (!seen.add(_rowKey(table, row))) {
        throw FormatException('ID ganda dalam bagian $table.');
      }
      return row;
    }).toList();
  }
  final rawMedia = decoded['media'];
  if (rawMedia is! List || rawMedia.length > JournalBackupService.maxRecords) {
    throw const FormatException('Daftar foto cadangan tidak valid.');
  }
  final media = <String, Uint8List>{};
  var totalBytes = 0;
  for (final raw in rawMedia) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Foto cadangan tidak valid.');
    }
    final id = _mediaId(_text(raw, 'id', max: 128));
    if (media.containsKey(id)) {
      throw const FormatException('ID foto ganda dalam cadangan.');
    }
    final encoded = _text(
      raw,
      'data',
      max: ((JournalMediaStore.maxPhotoBytes + 2) ~/ 3) * 4,
    );
    final photo = base64Decode(encoded);
    totalBytes += photo.length;
    if (totalBytes > JournalBackupService.maxMediaBytes) {
      throw const FormatException('Foto melebihi batas 128 MB per cadangan.');
    }
    JournalMediaStore.validatePhoto(photo);
    media[id] = photo;
  }
  final referencedMedia = <String>{};
  for (final table in ['family_members', 'moments']) {
    for (final row in tables[table]!) {
      final id = row['photo_path'] as String?;
      if (id == null) continue;
      if (!media.containsKey(id)) {
        throw const FormatException(
          'Foto yang dirujuk tidak ditemukan dalam cadangan.',
        );
      }
      referencedMedia.add(id);
    }
  }
  if (referencedMedia.length != media.length) {
    throw const FormatException('Cadangan memuat foto tanpa catatan pemilik.');
  }
  return _BackupPayload(tables, media, familyName, missingPhotos);
}

Map<String, Object?> _validateRow(String table, Map<String, dynamic> row) {
  if (table == 'ritual_checkins') {
    _onlyKeys(row, const {'ritual_id', 'day_key', 'completed_at'});
    final day = _text(row, 'day_key', max: 10);
    final parsed = DateTime.tryParse(day);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) ||
        parsed == null ||
        ritualDayKey(parsed) != day) {
      throw const FormatException('Tanggal centang kebiasaan tidak valid.');
    }
    return {
      'ritual_id': _text(row, 'ritual_id', max: 128),
      'day_key': day,
      'completed_at': _timestamp(row, 'completed_at'),
    };
  }
  final common = <String, Object?>{
    'id': _text(row, 'id', max: 128),
    'created_at': _timestamp(row, 'created_at'),
  };
  if (table == 'family_members') {
    _onlyKeys(row, const {
      'id',
      'created_at',
      'name',
      'role',
      'color_key',
      'photo_path',
    });
    return {
      ...common,
      'name': _text(row, 'name', max: 1000),
      'role': _text(row, 'role', max: 64),
      'color_key': _text(row, 'color_key', max: 64),
      'photo_path': _optionalMedia(row),
    };
  }
  if (table == 'rituals') {
    _onlyKeys(row, const {
      'id',
      'created_at',
      'title',
      'description',
      'time_of_day',
      'repeat_days',
      'accent_key',
      'is_archived',
    });
    final time = _text(row, 'time_of_day', max: 24);
    if (!RitualTimeOfDay.values.any((item) => item.name == time)) {
      throw const FormatException('Waktu kebiasaan tidak valid.');
    }
    final days = _text(row, 'repeat_days', max: 13);
    final parts = days.split(',');
    if (parts.toSet().length != parts.length ||
        parts.any((day) => !RegExp(r'^[1-7]$').hasMatch(day))) {
      throw const FormatException('Jadwal kebiasaan tidak valid.');
    }
    return {
      ...common,
      'title': _text(row, 'title', max: 1000),
      'description': _optionalText(row, 'description', max: 1000000),
      'time_of_day': time,
      'repeat_days': days,
      'accent_key': _text(row, 'accent_key', max: 64),
      'is_archived': _integer(row, 'is_archived', min: 0, max: 1),
    };
  }
  _onlyKeys(row, const {
    'id',
    'created_at',
    'title',
    'note',
    'tag',
    'member_id',
    'photo_path',
    'captured_at',
  });
  final tag = _text(row, 'tag', max: 24);
  if (!MomentTag.values.any((item) => item.name == tag)) {
    throw const FormatException('Suasana momen tidak valid.');
  }
  return {
    ...common,
    'title': _text(row, 'title', max: 1000),
    'note': _text(row, 'note', max: 1000000, allowEmpty: true),
    'tag': tag,
    'member_id': _optionalText(row, 'member_id', max: 128),
    'photo_path': _optionalMedia(row),
    'captured_at': _timestamp(row, 'captured_at'),
  };
}

void _onlyKeys(Map<String, dynamic> row, Set<String> keys) {
  if (row.keys.any((key) => !keys.contains(key)) ||
      keys.any((key) => !row.containsKey(key))) {
    throw const FormatException('Kolom catatan cadangan tidak sesuai format.');
  }
}

String _text(
  Map<String, dynamic> row,
  String key, {
  required int max,
  bool allowEmpty = false,
}) {
  final value = row[key];
  if (value is! String ||
      value.length > max ||
      value.contains('\u0000') ||
      (!allowEmpty && value.trim().isEmpty)) {
    throw FormatException('Nilai $key dalam cadangan tidak valid.');
  }
  return value;
}

String? _optionalText(
  Map<String, dynamic> row,
  String key, {
  required int max,
}) => row[key] == null
    ? null
    : _text(row, key, max: max, allowEmpty: key == 'description');

String? _optionalMedia(Map<String, dynamic> row) {
  final value = _optionalText(row, 'photo_path', max: 128);
  return value == null ? null : _mediaId(value);
}

String _mediaId(String value) {
  if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value)) {
    throw const FormatException('Referensi foto cadangan tidak valid.');
  }
  return value;
}

int _timestamp(Map<String, dynamic> row, String key) =>
    _integer(row, key, min: -62135596800000, max: 253402300799999);

int _integer(
  Map<String, dynamic> row,
  String key, {
  required int min,
  required int max,
}) {
  final value = row[key];
  if (value is! int || value < min || value > max) {
    throw FormatException('Nilai $key dalam cadangan tidak valid.');
  }
  return value;
}
