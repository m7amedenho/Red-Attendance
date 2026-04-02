import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/attendance_repository.dart';
import '../models/attendance_record.dart';
import '../models/export_result.dart';
import '../models/report_day_row.dart';
import '../utils/backup_service.dart';
import '../utils/date_utils_ar.dart';
import '../utils/export_service.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider({
    required this.repository,
    required this.prefs,
  });

  final AttendanceRepository repository;
  final SharedPreferences prefs;

  static const _clockInKey = 'active_clock_in';

  final List<AttendanceRecord> _records = [];
  Timer? _ticker;
  DateTime _now = DateTime.now();
  DateTime? _activeClockIn;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;
  String _monthlyNote = '';

  List<AttendanceRecord> get records => List.unmodifiable(_records);
  DateTime get now => _now;
  bool get isClockedIn => _activeClockIn != null;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  DateTime? get activeClockIn => _activeClockIn;
  String get monthlyNote => _monthlyNote;

  Duration get elapsed =>
      _activeClockIn == null ? Duration.zero : _now.difference(_activeClockIn!);

  List<ReportDayRow> get reportRowsForSelectedMonth {
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final totalDays = nextMonth.subtract(const Duration(days: 1)).day;

    final Map<String, AttendanceRecord> byDate = {};
    for (final record in _records) {
      byDate.putIfAbsent(record.date, () => record);
    }

    final rows = <ReportDayRow>[];
    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final key = DateUtilsAr.ymd(date);
      final record = byDate[key];
      if (record == null) {
        rows.add(ReportDayRow.empty(
          date: date,
          dayName: DateUtilsAr.arabicDayName(date),
        ));
      } else {
        rows.add(ReportDayRow.fromRecord(record, date));
      }
    }
    return rows;
  }

  Duration get totalWorkedDurationForSelectedMonth {
    Duration total = Duration.zero;
    for (final row in reportRowsForSelectedMonth) {
      total += row.workedDuration;
    }
    return total;
  }

  Future<void> initialize() async {
    _hydrateActiveClockIn();
    await reloadRecords();
    await loadMonthlyNoteForSelectedMonth();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  void _hydrateActiveClockIn() {
    final stored = prefs.getString(_clockInKey);
    if (stored != null) {
      _activeClockIn = DateTime.tryParse(stored);
    }
  }

  Future<void> setSelectedMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month);
    await loadMonthlyNoteForSelectedMonth();
    notifyListeners();
  }

  Future<void> loadMonthlyNoteForSelectedMonth() async {
    _monthlyNote = await getMonthlyNote(_selectedMonth) ?? '';
  }

  Future<void> reloadRecords() async {
    final fetched = await repository.getAll();
    _records
      ..clear()
      ..addAll(fetched);
    notifyListeners();
  }

  Future<void> clockIn() async {
    if (_activeClockIn != null) return;
    _activeClockIn = DateTime.now();
    await prefs.setString(_clockInKey, _activeClockIn!.toIso8601String());
    notifyListeners();
  }

  Future<void> clockOut() async {
    if (_activeClockIn == null) return;
    final end = DateTime.now();
    final start = _activeClockIn!;
    final recordDate = DateUtilsAr.ymd(start);
    final dayName = DateUtilsAr.arabicDayName(start);

    AttendanceRecord? existing;
    for (final item in _records) {
      if (item.date == recordDate) {
        existing = item;
        break;
      }
    }

    if (existing == null) {
      await repository.insert(
        AttendanceRecord(
          date: recordDate,
          dayName: dayName,
          clockIn: start,
          clockOut: end,
          notes: '',
        ),
      );
    } else {
      await repository.update(
        existing.copyWith(
          clockIn: existing.clockIn ?? start,
          clockOut: end,
        ),
      );
    }

    _activeClockIn = null;
    await prefs.remove(_clockInKey);
    await reloadRecords();
  }

  Future<void> upsertRecord(AttendanceRecord record) async {
    if (record.id == null) {
      await repository.insert(record);
    } else {
      await repository.update(record);
    }
    await reloadRecords();
  }

  Future<void> deleteRecord(int id) async {
    await repository.deleteById(id);
    await reloadRecords();
  }

  Future<ExportResult> exportCurrentMonthCsv() async {
    return ExportService.exportCsv(
      rows: reportRowsForSelectedMonth,
      totalWorkedDuration: totalWorkedDurationForSelectedMonth,
      month: _selectedMonth,
    );
  }

  Future<ExportResult> exportCurrentMonthPdf() async {
    return ExportService.exportPdf(
      rows: reportRowsForSelectedMonth,
      totalWorkedDuration: totalWorkedDurationForSelectedMonth,
      month: _selectedMonth,
      monthlyNote: _monthlyNote,
    );
  }

  Future<String?> getMonthlyNote(DateTime month) {
    return repository.getMonthNote(DateUtilsAr.monthKey(month));
  }

  Future<void> saveMonthlyNote(DateTime month, String note) async {
    await repository.saveMonthNote(
      monthKey: DateUtilsAr.monthKey(month),
      noteText: note.trim(),
    );
    await loadMonthlyNoteForSelectedMonth();
    notifyListeners();
  }

  Future<void> backupData() async {
    await BackupService.exportBackup(_records);
  }

  Future<bool> restoreDataFromBackup() async {
    final parsed = await BackupService.pickAndReadBackup();
    if (parsed == null) return false;
    await repository.replaceAll(parsed);
    await reloadRecords();
    return true;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
