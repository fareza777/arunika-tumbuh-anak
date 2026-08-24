import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/child.dart';

/// Akses data profil anak.
class ChildRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Child>> getAll() async {
    final db = await _db;
    final rows = await db.query('children', orderBy: 'created_at ASC');
    return rows.map(Child.fromMap).toList();
  }

  Future<Child?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Child.fromMap(rows.first);
  }

  Future<void> insert(Child child) async {
    final db = await _db;
    await db.insert(
      'children',
      child.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Child child) async {
    final db = await _db;
    await db.update(
      'children',
      child.toMap(),
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('children', where: 'id = ?', whereArgs: [id]);
  }

  // ── Backup/restore ───────────────────────────────────────────────────────

  Future<List<Map<String, Object?>>> getAllRaw() async {
    final db = await _db;
    return db.query('children');
  }

  /// Menyisipkan baris mentah; mengembalikan true bila benar-benar baru.
  Future<bool> insertRawIfNew(Map<String, Object?> row) async {
    final db = await _db;
    final existing = await db.query(
      'children',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [row['id']],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await db.insert('children', row);
    return true;
  }
}
