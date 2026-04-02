import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/export_result.dart';
import '../../models/report_day_row.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/attendance_row_color.dart';
import '../../utils/date_utils_ar.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقرير الشهري والتصدير')),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, _) {
          final rows = provider.reportRowsForSelectedMonth;
          final total = provider.totalWorkedDurationForSelectedMonth;

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _monthAndTotalCard(
                  month: provider.selectedMonth,
                  total: total,
                  onPickMonth: () => _pickMonth(context, provider),
                ),
                const SizedBox(height: 10),
                _actionsRow(context, provider),
                const SizedBox(height: 12),
                Expanded(child: _reportTable(rows)),
                const SizedBox(height: 10),
                _monthlyNoteCard(
                  note: provider.monthlyNote,
                  onEdit: () => _showMonthlyNoteDialog(context, provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _monthAndTotalCard({
    required DateTime month,
    required Duration total,
    required VoidCallback onPickMonth,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'الشهر الحالي: ${DateUtilsAr.monthYear(month)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onPickMonth,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('تغيير الشهر'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إجمالي ساعات العمل: ${DateUtilsAr.hmsDuration(total)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionsRow(BuildContext context, AttendanceProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await provider.exportCurrentMonthCsv();
                  if (!context.mounted) return;
                  _showResultSnack(context, result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.table_chart),
                label: const Text('تصدير CSV'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await provider.exportCurrentMonthPdf();
                  if (!context.mounted) return;
                  _showResultSnack(context, result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('تصدير PDF'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await provider.backupData();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إنشاء نسخة احتياطية ومشاركتها')),
                  );
                },
                icon: const Icon(Icons.backup_outlined),
                label: const Text('نسخ احتياطي'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await provider.restoreDataFromBackup();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'تمت استعادة النسخة الاحتياطية' : 'لم يتم اختيار ملف صالح',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.restore_outlined),
                label: const Text('استعادة نسخة'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reportTable(List<ReportDayRow> rows) {
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
              columns: const [
                DataColumn(label: Text('الملاحظات')),
                DataColumn(label: Text('ساعات اليوم')),
                DataColumn(label: Text('وقت الانصراف')),
                DataColumn(label: Text('وقت الحضور')),
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('اليوم')),
              ],
              rows: rows.map((row) {
                return DataRow(
                  color: WidgetStateProperty.all(rowColorForReport(row)),
                  cells: [
                    DataCell(Text(row.notes)),
                    DataCell(Text(DateUtilsAr.hmsDuration(row.workedDuration))),
                    DataCell(Text(DateUtilsAr.hm(row.clockOut))),
                    DataCell(Text(DateUtilsAr.hm(row.clockIn))),
                    DataCell(Text(DateUtilsAr.ymd(row.date))),
                    DataCell(Text(row.dayName)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthlyNoteCard({
    required String note,
    required VoidCallback onEdit,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ملاحظات الشهر',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('تعديل'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              note.trim().isEmpty ? '-' : note.trim(),
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context, AttendanceProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      locale: const Locale('ar'),
      helpText: 'اختر أي يوم من الشهر المطلوب',
    );
    if (picked != null) {
      await provider.setSelectedMonth(DateTime(picked.year, picked.month));
    }
  }

  Future<void> _showMonthlyNoteDialog(
    BuildContext context,
    AttendanceProvider provider,
  ) async {
    final controller = TextEditingController(text: provider.monthlyNote);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل ملاحظات الشهر'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'اكتب ملاحظات الشهر هنا',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await provider.saveMonthlyNote(provider.selectedMonth, controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('تم حفظ ملاحظات الشهر')),
      );
    }
  }

  void _showResultSnack(BuildContext context, ExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.success ? const Color(0xFF166534) : const Color(0xFFB91C1C),
        content: Text(result.message),
      ),
    );
  }
}
