import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/ritual.dart';
import '../models/ritual_check_in.dart';

class RitualRepository {
  RitualRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  Future<Database> get _db => _database.database;

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
    // REPLACE deletes the parent first and cascades to every completed day.
    await db.transaction((txn) async {
      final updated = await txn.update(
        'rituals',
        ritual.toMap(),
        where: 'id = ?',
        whereArgs: [ritual.id],
      );
      if (updated == 0) await txn.insert('rituals', ritual.toMap());
    });
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

  Future<void> restore(String id) async {
    final db = await _db;
    await db.update(
      'rituals',
      {'is_archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Stable IDs make retries safe. Matching titles also recognize partial
  /// starter sets created by older versions that used random IDs.
  Future<void> insertStartersIfMissing(List<Ritual> starters) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query('rituals', columns: ['id', 'title']);
      final ids = rows.map((row) => row['id']! as String).toSet();
      final titles = rows
          .map((row) => (row['title']! as String).trim().toLowerCase())
          .toSet();
      final batch = txn.batch();
      for (final ritual in starters) {
        final title = ritual.title.trim().toLowerCase();
        if (ids.contains(ritual.id) || titles.contains(title)) continue;
        ids.add(ritual.id);
        titles.add(title);
        batch.insert('rituals', ritual.toMap());
      }
      await batch.commit(noResult: true);
    });
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

  Future<List<RitualCheckIn>> getCheckIns({int? limit}) async {
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
