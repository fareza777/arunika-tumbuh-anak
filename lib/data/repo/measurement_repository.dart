import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/measurement.dart';

/// Akses data pengukuran antropometri.
class MeasurementRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  /// Riwayat pengukuran satu anak, urut tanggal naik.
  Future<List<Measurement>> getForChild(String childId) async {
    final db = await _db;
    final rows = await db.query(
      'measurements',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date ASC',
    );
    return rows.map(Measurement.fromMap).toList();
  }

  Future<Measurement?> getLatest(String childId) async {
    final db = await _db;
    final rows = await db.query(
      'measurements',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Measurement.fromMap(rows.first);
  }

  Future<void> insert(Measurement measurement) async {
    final db = await _db;
    await db.insert(
      'measurements',
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Measurement measurement) async {
    final db = await _db;
    await db.update(
      'measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  // ── Backup/restore ───────────────────────────────────────────────────────

  Future<List<Map<String, Object?>>> getAllRaw() async {
    final db = await _db;
    return db.query('measurements');
  }

  Future<bool> insertRawIfNew(Map<String, Object?> row) async {
    final db = await _db;
    final existing = await db.query(
      'measurements',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [row['id']],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await db.insert('measurements', row);
    return true;
  }
}
