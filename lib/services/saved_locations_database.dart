import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SavedLocationsDatabase {
  static const _dbName = 'saved_locations.db';
  static const _dbVersion = 1;
  static const table = 'saved_locations';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          place_id TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          saved_at INTEGER NOT NULL
        )
      '''),
    );
  }

  Future<void> insert(Map<String, dynamic> row) async {
    final db = await _database;
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> delete(String placeId) async {
    final db = await _database;
    await db.delete(table, where: 'place_id = ?', whereArgs: [placeId]);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _database;
    return db.query(table, orderBy: 'saved_at DESC');
  }

  Future<bool> exists(String placeId) async {
    final db = await _database;
    final rows = await db.query(
      table,
      columns: ['id'],
      where: 'place_id = ?',
      whereArgs: [placeId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
