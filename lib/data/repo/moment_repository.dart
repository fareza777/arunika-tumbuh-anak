import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/moment.dart';

class MomentRepository {
  MomentRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  Future<Database> get _db => _database.database;

  /// A limit is opt-in; aggregate and export callers receive the whole journal.
  Future<List<Moment>> getRecent({int? limit}) async {
    final db = await _db;
    final rows = await db.query(
      'moments',
      orderBy: 'captured_at DESC, created_at DESC, id DESC',
      limit: limit,
    );
    return rows.map(Moment.fromMap).toList();
  }

  Future<List<Moment>> getAll() => getRecent();

  Future<List<Moment>> getPage({
    int limit = 30,
    int offset = 0,
    String? query,
    MomentTag? tag,
  }) async {
    if (limit < 1 || limit > 200 || offset < 0) {
      throw ArgumentError('Ukuran atau posisi halaman tidak valid.');
    }
    final clauses = <String>[];
    final arguments = <Object?>[];
    final term = query?.trim();
    if (term != null && term.isNotEmpty) {
      final escaped = term
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      clauses.add("(title LIKE ? ESCAPE '\\' OR note LIKE ? ESCAPE '\\')");
      arguments.addAll(['%$escaped%', '%$escaped%']);
    }
    if (tag != null) {
      clauses.add('tag = ?');
      arguments.add(tag.name);
    }
    final db = await _db;
    final rows = await db.query(
      'moments',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: arguments,
      orderBy: 'captured_at DESC, created_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(Moment.fromMap).toList();
  }

  Future<void> save(Moment moment) async {
    final db = await _db;
    await db.transaction((txn) async {
      final updated = await txn.update(
        'moments',
        moment.toMap(),
        where: 'id = ?',
        whereArgs: [moment.id],
      );
      if (updated == 0) await txn.insert('moments', moment.toMap());
    });
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('moments', where: 'id = ?', whereArgs: [id]);
  }
}
