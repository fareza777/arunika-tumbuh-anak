import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/family_member.dart';

class FamilyMemberRepository {
  FamilyMemberRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  Future<Database> get _db => _database.database;

  Future<List<FamilyMember>> getAll() async {
    final db = await _db;
    final rows = await db.query('family_members', orderBy: 'created_at ASC');
    return rows.map(FamilyMember.fromMap).toList();
  }

  Future<FamilyMember?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'family_members',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : FamilyMember.fromMap(rows.first);
  }

  Future<void> insert(FamilyMember member) async {
    final db = await _db;
    await db.transaction((txn) async {
      final updated = await txn.update(
        'family_members',
        member.toMap(),
        where: 'id = ?',
        whereArgs: [member.id],
      );
      if (updated == 0) await txn.insert('family_members', member.toMap());
    });
  }

  Future<void> update(FamilyMember member) async {
    final db = await _db;
    await db.update(
      'family_members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
  }
}
