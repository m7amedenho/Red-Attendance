class AttendanceRecord {
  const AttendanceRecord({
    this.id,
    required this.date,
    required this.dayName,
    this.clockIn,
    this.clockOut,
    this.notes = '',
  });

  final int? id;
  final String date; // yyyy-MM-dd
  final String dayName; // Arabic weekday
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String notes;

  AttendanceRecord copyWith({
    int? id,
    String? date,
    String? dayName,
    DateTime? clockIn,
    DateTime? clockOut,
    String? notes,
    bool clearClockIn = false,
    bool clearClockOut = false,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      dayName: dayName ?? this.dayName,
      clockIn: clearClockIn ? null : (clockIn ?? this.clockIn),
      clockOut: clearClockOut ? null : (clockOut ?? this.clockOut),
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'day_name': dayName,
      'clock_in': clockIn?.toIso8601String(),
      'clock_out': clockOut?.toIso8601String(),
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, Object?> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      dayName: map['day_name'] as String? ?? '',
      clockIn: map['clock_in'] != null
          ? DateTime.tryParse(map['clock_in'] as String)
          : null,
      clockOut: map['clock_out'] != null
          ? DateTime.tryParse(map['clock_out'] as String)
          : null,
      notes: map['notes'] as String? ?? '',
    );
  }
}
