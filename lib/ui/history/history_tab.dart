import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/date_utils_ar.dart';
import 'record_editor_screen.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السجل والتعديل اليدوي')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RecordEditorScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة يوم'),
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.records.isEmpty) {
            return const Center(child: Text('لا توجد سجلات بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
            itemCount: provider.records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = provider.records[index];
              return _RecordTile(record: record);
            },
          );
        },
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        title: Text(
          '${record.dayName} - ${record.date}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('وقت الحضور: ${DateUtilsAr.hm(record.clockIn)}'),
              Text('وقت الانصراف: ${DateUtilsAr.hm(record.clockOut)}'),
              if (record.notes.trim().isNotEmpty) Text('الملاحظات: ${record.notes}'),
            ],
          ),
        ),
        trailing: const Icon(Icons.edit_square),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecordEditorScreen(record: record),
            ),
          );
        },
      ),
    );
  }
}
