class MonthlyNote {
  const MonthlyNote({
    required this.monthKey,
    required this.noteText,
    required this.updatedAt,
  });

  final String monthKey; // yyyy-MM
  final String noteText;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'month_key': monthKey,
      'note_text': noteText,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MonthlyNote.fromMap(Map<String, Object?> map) {
    return MonthlyNote(
      monthKey: map['month_key'] as String? ?? '',
      noteText: map['note_text'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
