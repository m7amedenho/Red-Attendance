import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _init();
    return _database!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'attendance_tracker.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            day_name TEXT NOT NULL,
            clock_in TEXT,
            clock_out TEXT,
            notes TEXT DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE month_notes (
            month_key TEXT PRIMARY KEY,
            note_text TEXT NOT NULL DEFAULT '',
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS month_notes (
              month_key TEXT PRIMARY KEY,
              note_text TEXT NOT NULL DEFAULT '',
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }
}
