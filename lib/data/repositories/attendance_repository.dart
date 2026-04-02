import '../../models/attendance_record.dart';
import '../../models/monthly_note.dart';
import '../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class AttendanceRepository {
  const AttendanceRepository(this._db);

  final AppDatabase _db;

  Future<List<AttendanceRecord>> getAll() async {
    final database = await _db.database;
    final rows = await database.query(
      'attendance',
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  Future<int> insert(AttendanceRecord record) async {
    final database = await _db.database;
    return database.insert('attendance', record.toMap());
  }

  Future<int> update(AttendanceRecord record) async {
    final database = await _db.database;
    return database.update(
      'attendance',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteById(int id) async {
    final database = await _db.database;
    return database.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAll(List<AttendanceRecord> records) async {
    final database = await _db.database;
    await database.transaction((txn) async {
      await txn.delete('attendance');
      for (final record in records) {
        final map = record.toMap()..remove('id');
        await txn.insert('attendance', map);
      }
    });
  }

  Future<String?> getMonthNote(String monthKey) async {
    final database = await _db.database;
    final rows = await database.query(
      'month_notes',
      where: 'month_key = ?',
      whereArgs: [monthKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final note = MonthlyNote.fromMap(rows.first);
    return note.noteText;
  }

  Future<void> saveMonthNote({
    required String monthKey,
    required String noteText,
  }) async {
    final database = await _db.database;
    final note = MonthlyNote(
      monthKey: monthKey,
      noteText: noteText,
      updatedAt: DateTime.now(),
    );
    await database.insert(
      'month_notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
