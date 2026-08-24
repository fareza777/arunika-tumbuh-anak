import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database SQLite lokal — seluruh data anak tersimpan privat di perangkat.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'arunika.db');
    _db = await openDatabase(
      path,
      version: 3,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: dukungan usia kehamilan (koreksi prematur) + checklist gizi harian.
      await db.execute(
        'ALTER TABLE children ADD COLUMN gestational_weeks INTEGER',
      );
      await _createNutritionLogTable(db);
    }
    if (oldVersion < 3) {
      await _createTogetherTables(db);
      // A legacy display name can safely become a family member label. No
      // measurement or clinical field is copied into the new product slice.
      await db.execute('''
        INSERT OR IGNORE INTO family_members
          (id, name, role, color_key, photo_path, created_at)
        SELECT id, name, 'family', 'sunrise', photo_path, created_at
        FROM children
      ''');
    }
  }

  Future<void> _createNutritionLogTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutrition_log (
        child_id TEXT NOT NULL,
        log_date TEXT NOT NULL,
        item_id TEXT NOT NULL,
        checked INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (child_id, log_date, item_id),
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        birth_date INTEGER NOT NULL,
        photo_path TEXT,
        birth_weight REAL,
        birth_height REAL,
        birth_head REAL,
        father_height REAL,
        mother_height REAL,
        gestational_weeks INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE measurements (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        weight REAL,
        height REAL,
        head REAL,
        muac REAL,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_measurements_child_date ON measurements (child_id, date)',
    );

    await db.execute('''
      CREATE TABLE milestone_status (
        child_id TEXT NOT NULL,
        milestone_id TEXT NOT NULL,
        achieved INTEGER NOT NULL DEFAULT 0,
        achieved_date INTEGER,
        PRIMARY KEY (child_id, milestone_id),
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE immunization_status (
        child_id TEXT NOT NULL,
        vaccine_id TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        done_date INTEGER,
        PRIMARY KEY (child_id, vaccine_id),
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');

    await _createNutritionLogTable(db);
    await _createTogetherTables(db);
  }

  Future<void> _createTogetherTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS family_members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'family',
        color_key TEXT NOT NULL DEFAULT 'sunrise',
        photo_path TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rituals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        time_of_day TEXT NOT NULL DEFAULT 'anytime',
        repeat_days TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        accent_key TEXT NOT NULL DEFAULT 'sage',
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ritual_checkins (
        ritual_id TEXT NOT NULL,
        day_key TEXT NOT NULL,
        completed_at INTEGER NOT NULL,
        PRIMARY KEY (ritual_id, day_key),
        FOREIGN KEY (ritual_id) REFERENCES rituals (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS moments (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT NOT NULL,
        tag TEXT NOT NULL DEFAULT 'together',
        member_id TEXT,
        photo_path TEXT,
        captured_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (member_id) REFERENCES family_members (id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_moments_captured_at ON moments (captured_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ritual_checkins_day ON ritual_checkins (day_key)',
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
