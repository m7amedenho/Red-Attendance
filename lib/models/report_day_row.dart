import 'attendance_record.dart';

class ReportDayRow {
  const ReportDayRow({
    required this.date,
    required this.dayName,
    required this.clockIn,
    required this.clockOut,
    required this.notes,
    required this.hasRecord,
  });

  final DateTime date;
  final String dayName;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String notes;
  final bool hasRecord;

  Duration get workedDuration {
    if (clockIn == null || clockOut == null) return Duration.zero;
    final diff = clockOut!.difference(clockIn!);
    return diff.isNegative ? Duration.zero : diff;
  }

  factory ReportDayRow.fromRecord(AttendanceRecord record, DateTime parsedDate) {
    return ReportDayRow(
      date: parsedDate,
      dayName: record.dayName,
      clockIn: record.clockIn,
      clockOut: record.clockOut,
      notes: record.notes.trim().isEmpty ? '-' : record.notes.trim(),
      hasRecord: true,
    );
  }

  factory ReportDayRow.empty({
    required DateTime date,
    required String dayName,
  }) {
    return ReportDayRow(
      date: date,
      dayName: dayName,
      clockIn: null,
      clockOut: null,
      notes: '-',
      hasRecord: false,
    );
  }
}
