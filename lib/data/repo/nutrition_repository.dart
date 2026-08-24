import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';

/// Akses data checklist gizi harian per anak per tanggal.
class NutritionRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Item yang dicentang pada tanggal tertentu.
  Future<Set<String>> getCheckedItems(String childId, DateTime date) async {
    final db = await _db;
    final rows = await db.query(
      'nutrition_log',
      columns: ['item_id'],
      where: 'child_id = ? AND log_date = ? AND checked = 1',
      whereArgs: [childId, dateKey(date)],
    );
    return rows.map((r) => r['item_id'] as String).toSet();
  }

  Future<void> setItem(
    String childId,
    DateTime date,
    String itemId,
    bool checked,
  ) async {
    final db = await _db;
    await db.insert('nutrition_log', {
      'child_id': childId,
      'log_date': dateKey(date),
      'item_id': itemId,
      'checked': checked ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Backup/restore ───────────────────────────────────────────────────────

  Future<List<Map<String, Object?>>> getAllRaw() async {
    final db = await _db;
    return db.query('nutrition_log');
  }

  Future<bool> insertRawIfNew(Map<String, Object?> row) async {
    final db = await _db;
    final existing = await db.query(
      'nutrition_log',
      columns: ['child_id'],
      where: 'child_id = ? AND log_date = ? AND item_id = ?',
      whereArgs: [row['child_id'], row['log_date'], row['item_id']],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await db.insert('nutrition_log', row);
    return true;
  }
}
