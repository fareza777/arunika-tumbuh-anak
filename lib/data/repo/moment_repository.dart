import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/moment.dart';

class MomentRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Moment>> getRecent({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      'moments',
      orderBy: 'captured_at DESC',
      limit: limit,
    );
    return rows.map(Moment.fromMap).toList();
  }

  Future<List<Moment>> getAll() => getRecent(limit: 500);

  Future<void> save(Moment moment) async {
    final db = await _db;
    await db.insert(
      'moments',
      moment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('moments', where: 'id = ?', whereArgs: [id]);
  }
}
