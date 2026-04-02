import 'package:intl/intl.dart';

class DateUtilsAr {
  static const Map<int, String> _weekdayArabic = {
    DateTime.monday: 'الاثنين',
    DateTime.tuesday: 'الثلاثاء',
    DateTime.wednesday: 'الأربعاء',
    DateTime.thursday: 'الخميس',
    DateTime.friday: 'الجمعة',
    DateTime.saturday: 'السبت',
    DateTime.sunday: 'الأحد',
  };

  static String arabicDayName(DateTime date) => _weekdayArabic[date.weekday] ?? '';

  static String ymd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String monthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

  static String clock(DateTime date) => DateFormat('HH:mm:ss').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM yyyy', 'ar').format(date);

  static String dateHeader(DateTime date) =>
      DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);

  static String hm(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('HH:mm').format(date);
  }

  static String hmsDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
