import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class HexaIQDatabase {
  HexaIQDatabase({this.factory, this.databasePath});

  final DatabaseFactory? factory;
  final String? databasePath;
  Database? _database;

  Future<Database> open() async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    final factory = _resolvedFactory();
    final path =
        databasePath ?? p.join(await factory.getDatabasesPath(), 'hexaiq.db');
    _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await _createSchema(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _createSchema(db);
        },
        onOpen: (db) async {
          await _createSchema(db);
        },
      ),
    );
    return _database!;
  }

  DatabaseFactory _resolvedFactory() {
    final provided = factory;
    if (provided != null) {
      return provided;
    }
    try {
      return databaseFactory;
    } on StateError {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
  }

  Future<void> close() async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      await existing.close();
    }
    _database = null;
  }

  Future<void> clearAll() async {
    final db = await open();
    for (final table in [
      'profiles',
      'test_results',
      'training_results',
      'calibration_profiles',
      'settings',
      'export_jobs',
      'active_test_sessions',
    ]) {
      await db.delete(table);
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  age_group TEXT NOT NULL,
  grade TEXT NOT NULL,
  avatar TEXT NOT NULL,
  age INTEGER NOT NULL DEFAULT 0,
  recent_iq INTEGER NOT NULL DEFAULT 100,
  recent_percentile INTEGER NOT NULL DEFAULT 50,
  recent_ability_level TEXT NOT NULL DEFAULT '평균',
  last_test_at TEXT,
  test_count INTEGER NOT NULL DEFAULT 0
)
''');
    await _ensureColumn(
      db,
      table: 'profiles',
      column: 'recent_percentile',
      definition: 'INTEGER NOT NULL DEFAULT 50',
    );
    await _ensureColumn(
      db,
      table: 'profiles',
      column: 'recent_ability_level',
      definition: "TEXT NOT NULL DEFAULT '평균'",
    );
    await db.execute('''
CREATE TABLE IF NOT EXISTS test_results (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL,
  started_at TEXT NOT NULL,
  completed_at TEXT NOT NULL,
  theta REAL NOT NULL,
  standard_error REAL NOT NULL,
  estimated_iq INTEGER NOT NULL,
  percentile INTEGER NOT NULL,
  ability_level TEXT NOT NULL,
  average_difficulty TEXT NOT NULL,
  average_elapsed_seconds INTEGER NOT NULL,
  question_count INTEGER NOT NULL,
  payload_json TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS training_results (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL,
  selected_domains TEXT NOT NULL,
  selected_difficulty TEXT NOT NULL,
  question_count INTEGER NOT NULL,
  correct_count INTEGER NOT NULL,
  completed_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS calibration_profiles (
  item_id TEXT PRIMARY KEY,
  response_count INTEGER NOT NULL,
  correct_count INTEGER NOT NULL,
  correct_rate REAL NOT NULL,
  average_theta REAL NOT NULL,
  average_response_time_ms REAL NOT NULL,
  difficulty REAL NOT NULL,
  discrimination REAL NOT NULL,
  guessing REAL NOT NULL,
  upper_asymptote REAL NOT NULL,
  updated_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS export_jobs (
  id TEXT PRIMARY KEY,
  format TEXT NOT NULL,
  created_at TEXT NOT NULL,
  payload TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS active_test_sessions (
  profile_id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  }

  Future<void> _ensureColumn(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (exists) {
      return;
    }
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }
}
