import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/date_utils_ar.dart';

class RecordEditorScreen extends StatefulWidget {
  const RecordEditorScreen({
    super.key,
    this.record,
  });

  final AttendanceRecord? record;

  @override
  State<RecordEditorScreen> createState() => _RecordEditorScreenState();
}

class _RecordEditorScreenState extends State<RecordEditorScreen> {
  late DateTime _selectedDate;
  TimeOfDay? _clockInTime;
  TimeOfDay? _clockOutTime;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.record == null
        ? DateTime.now()
        : (DateTime.tryParse(widget.record!.date) ?? DateTime.now());
    _clockInTime = _fromDateTime(widget.record?.clockIn);
    _clockOutTime = _fromDateTime(widget.record?.clockOut);
    _notesController = TextEditingController(text: widget.record?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  TimeOfDay? _fromDateTime(DateTime? value) {
    if (value == null) return null;
    return TimeOfDay(hour: value.hour, minute: value.minute);
  }

  DateTime? _merge(DateTime date, TimeOfDay? time) {
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isClockIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isClockIn ? _clockInTime : _clockOutTime) ??
          const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      setState(() {
        if (isClockIn) {
          _clockInTime = picked;
        } else {
          _clockOutTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final inDate = _merge(_selectedDate, _clockInTime);
    final outDate = _merge(_selectedDate, _clockOutTime);

    if (inDate != null && outDate != null && outDate.isBefore(inDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وقت الانصراف يجب أن يكون بعد وقت الحضور')),
      );
      return;
    }

    final record = AttendanceRecord(
      id: widget.record?.id,
      date: DateUtilsAr.ymd(_selectedDate),
      dayName: DateUtilsAr.arabicDayName(_selectedDate),
      clockIn: inDate,
      clockOut: outDate,
      notes: _notesController.text.trim(),
    );

    await context.read<AttendanceProvider>().upsertRecord(record);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.record?.id;
    if (id == null) return;
    await context.read<AttendanceProvider>().deleteRecord(id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.record != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل سجل' : 'إضافة سجل'),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _editorCard(
            context: context,
            title: 'التاريخ',
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(DateUtilsAr.ymd(_selectedDate)),
            ),
          ),
          const SizedBox(height: 10),
          _editorCard(
            context: context,
            title: 'وقت الحضور',
            child: OutlinedButton.icon(
              onPressed: () => _pickTime(true),
              icon: const Icon(Icons.login),
              label: Text(_clockInTime == null ? '-' : _clockInTime!.format(context)),
            ),
          ),
          const SizedBox(height: 10),
          _editorCard(
            context: context,
            title: 'وقت الانصراف',
            child: OutlinedButton.icon(
              onPressed: () => _pickTime(false),
              icon: const Icon(Icons.logout),
              label: Text(_clockOutTime == null ? '-' : _clockOutTime!.format(context)),
            ),
          ),
          const SizedBox(height: 10),
          _editorCard(
            context: context,
            title: 'الملاحظات',
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'مثال: غياب / إذن / تأخير',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _editorCard({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
