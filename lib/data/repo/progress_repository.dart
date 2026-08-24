import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';

/// Status pencapaian milestone perkembangan dan imunisasi per anak.
class ProgressRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  // ── Milestone ────────────────────────────────────────────────────────────

  Future<Map<String, DateTime?>> getMilestoneStatus(String childId) async {
    final db = await _db;
    final rows = await db.query(
      'milestone_status',
      where: 'child_id = ? AND achieved = 1',
      whereArgs: [childId],
    );
    return {
      for (final row in rows)
        row['milestone_id'] as String: row['achieved_date'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['achieved_date'] as int),
    };
  }

  Future<void> setMilestoneAchieved(
    String childId,
    String milestoneId,
    bool achieved,
  ) async {
    final db = await _db;
    await db.insert('milestone_status', {
      'child_id': childId,
      'milestone_id': milestoneId,
      'achieved': achieved ? 1 : 0,
      'achieved_date': achieved ? DateTime.now().millisecondsSinceEpoch : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Imunisasi ────────────────────────────────────────────────────────────

  Future<Map<String, DateTime?>> getImmunizationStatus(String childId) async {
    final db = await _db;
    final rows = await db.query(
      'immunization_status',
      where: 'child_id = ? AND done = 1',
      whereArgs: [childId],
    );
    return {
      for (final row in rows)
        row['vaccine_id'] as String: row['done_date'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['done_date'] as int),
    };
  }

  Future<void> setImmunizationDone(
    String childId,
    String vaccineId,
    bool done,
  ) async {
    final db = await _db;
    await db.insert('immunization_status', {
      'child_id': childId,
      'vaccine_id': vaccineId,
      'done': done ? 1 : 0,
      'done_date': done ? DateTime.now().millisecondsSinceEpoch : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Backup/restore ───────────────────────────────────────────────────────

  Future<List<Map<String, Object?>>> getAllMilestoneRaw() async {
    final db = await _db;
    return db.query('milestone_status');
  }

  Future<List<Map<String, Object?>>> getAllImmunizationRaw() async {
    final db = await _db;
    return db.query('immunization_status');
  }

  Future<bool> insertMilestoneRawIfNew(Map<String, Object?> row) async {
    final db = await _db;
    final existing = await db.query(
      'milestone_status',
      columns: ['child_id'],
      where: 'child_id = ? AND milestone_id = ?',
      whereArgs: [row['child_id'], row['milestone_id']],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await db.insert('milestone_status', row);
    return true;
  }

  Future<bool> insertImmunizationRawIfNew(Map<String, Object?> row) async {
    final db = await _db;
    final existing = await db.query(
      'immunization_status',
      columns: ['child_id'],
      where: 'child_id = ? AND vaccine_id = ?',
      whereArgs: [row['child_id'], row['vaccine_id']],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await db.insert('immunization_status', row);
    return true;
  }
}
