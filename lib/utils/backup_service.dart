import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attendance_record.dart';
import 'date_utils_ar.dart';

class BackupService {
  static Future<void> exportBackup(List<AttendanceRecord> records) async {
    final payload = {
      'version': 1,
      'created_at': DateTime.now().toIso8601String(),
      'records': records.map((e) {
        final map = e.toMap();
        map.remove('id');
        return map;
      }).toList(),
    };

    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/attendance_backup_${DateUtilsAr.ymd(DateTime.now())}.json');
    await file.writeAsString(jsonText, encoding: utf8, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        text: 'نسخة احتياطية لبيانات الحضور',
        files: [XFile(file.path)],
      ),
    );
  }

  static Future<List<AttendanceRecord>?> pickAndReadBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;

    final text = await File(path).readAsString(encoding: utf8);
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) return null;
    final records = decoded['records'];
    if (records is! List) return null;

    return records
        .whereType<Map>()
        .map((e) => AttendanceRecord.fromMap(Map<String, Object?>.from(e)))
        .toList();
  }
}
