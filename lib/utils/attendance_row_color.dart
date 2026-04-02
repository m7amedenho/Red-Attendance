import 'package:flutter/material.dart';

import '../models/report_day_row.dart';

const Color absenceColor = Color(0xFFFFE5E5);
const Color vacationColor = Color(0xFFE6F0FF);
const Color delayColor = Color(0xFFFFF0DD);
const Color fridayColor = Color(0xFFFFF7CC);
const Color normalColor = Colors.white;

String? detectStatusKeyword(String notes) {
  final value = notes.trim();
  if (value.contains('غياب')) return 'absence';
  if (value.contains('إجازة') || value.contains('اجازة')) return 'vacation';
  if (value.contains('تأخير')) return 'delay';
  return null;
}

Color rowColorForReport(ReportDayRow row) {
  final status = detectStatusKeyword(row.notes);
  if (status == 'absence') return absenceColor;
  if (status == 'vacation') return vacationColor;
  if (status == 'delay') return delayColor;
  if (row.dayName == 'الجمعة') return fridayColor;
  return normalColor;
}
