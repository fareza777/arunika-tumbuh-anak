import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/ritual.dart';
import '../models/ritual_check_in.dart';

class RitualRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Ritual>> getAll({bool includeArchived = false}) async {
    final db = await _db;
    final rows = await db.query(
      'rituals',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'created_at ASC',
    );
    return rows.map(Ritual.fromMap).toList();
  }

  Future<List<Ritual>> getScheduledFor(DateTime date) async {
    final rituals = await getAll();
    return rituals.where((ritual) => ritual.isScheduledFor(date)).toList();
  }

  Future<void> save(Ritual ritual) async {
    final db = await _db;
    await db.insert(
      'rituals',
      ritual.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> archive(String id) async {
    final db = await _db;
    await db.update(
      'rituals',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Set<String>> getCompletedIdsFor(DateTime date) async {
    final db = await _db;
    final rows = await db.query(
      'ritual_checkins',
      columns: ['ritual_id'],
      where: 'day_key = ?',
      whereArgs: [ritualDayKey(date)],
    );
    return rows.map((row) => row['ritual_id']! as String).toSet();
  }

  Future<List<RitualCheckIn>> getCheckIns({int limit = 100}) async {
    final db = await _db;
    final rows = await db.query(
      'ritual_checkins',
      orderBy: 'completed_at DESC',
      limit: limit,
    );
    return rows.map(RitualCheckIn.fromMap).toList();
  }

  Future<void> setCheckIn(
    String ritualId,
    DateTime date,
    bool completed,
  ) async {
    final db = await _db;
    final dayKey = ritualDayKey(date);
    if (!completed) {
      await db.delete(
        'ritual_checkins',
        where: 'ritual_id = ? AND day_key = ?',
        whereArgs: [ritualId, dayKey],
      );
      return;
    }
    await db.insert(
      'ritual_checkins',
      RitualCheckIn(
        ritualId: ritualId,
        dayKey: dayKey,
        completedAt: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
