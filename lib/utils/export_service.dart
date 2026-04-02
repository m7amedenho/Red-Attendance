import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/export_result.dart';
import '../models/report_day_row.dart';
import 'attendance_row_color.dart';
import 'date_utils_ar.dart';

class ExportService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  static Future<ExportResult> exportCsv({
    required List<ReportDayRow> rows,
    required Duration totalWorkedDuration,
    required DateTime month,
  }) async {
    try {
      final table = <List<String>>[
        ['الملاحظات', 'ساعات اليوم', 'وقت الانصراف', 'وقت الحضور', 'التاريخ', 'اليوم'],
        ...rows.map((row) {
          return [
            row.notes,
            DateUtilsAr.hmsDuration(row.workedDuration),
            DateUtilsAr.hm(row.clockOut),
            DateUtilsAr.hm(row.clockIn),
            DateUtilsAr.ymd(row.date),
            row.dayName,
          ];
        }),
        ['إجمالي ساعات العمل', DateUtilsAr.hmsDuration(totalWorkedDuration), '', '', '', ''],
      ];

      final csvText = const ListToCsvConverter().convert(table);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/attendance_${DateUtilsAr.monthKey(month)}.csv');

      final bom = [0xEF, 0xBB, 0xBF];
      final bytes = <int>[...bom, ...utf8.encode(csvText)];
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          text: 'تقرير الحضور والانصراف (CSV)',
          files: [XFile(file.path)],
        ),
      );

      return const ExportResult(success: true, message: 'تم تصدير CSV بنجاح');
    } catch (e) {
      return ExportResult(success: false, message: 'فشل تصدير CSV: $e');
    }
  }

  static Future<ExportResult> exportPdf({
    required List<ReportDayRow> rows,
    required Duration totalWorkedDuration,
    required DateTime month,
    required String monthlyNote,
  }) async {
    try {
      await _ensureFontsLoaded();
      if (_regularFont == null || _boldFont == null) {
        return const ExportResult(
          success: false,
          message: 'تعذر تحميل خطوط PDF. تأكد من وجود خطوط Alexandria داخل assets/static.',
        );
      }

      final regularFont = _regularFont!;
      final boldFont = _boldFont!;
      final doc = pw.Document();

      final tableRows = rows.map((row) {
        final color = PdfColor.fromInt(rowColorForReport(row).toARGB32());
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: color),
          children: [
            _pdfCell(row.notes, regularFont),
            _pdfCell(DateUtilsAr.hmsDuration(row.workedDuration), regularFont),
            _pdfCell(DateUtilsAr.hm(row.clockOut), regularFont),
            _pdfCell(DateUtilsAr.hm(row.clockIn), regularFont),
            _pdfCell(DateUtilsAr.ymd(row.date), regularFont),
            _pdfCell(row.dayName, regularFont),
          ],
        );
      }).toList();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (_) {
            return [
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(
                      'سجل الحضور والانصراف - محمد حامد | Codly',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'الشهر: ${DateUtilsAr.monthYear(month)}',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: regularFont, fontSize: 11),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'إجمالي ساعات العمل: ${DateUtilsAr.hmsDuration(totalWorkedDuration)}',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: boldFont, fontSize: 11),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey500),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            _pdfHeader('الملاحظات', boldFont),
                            _pdfHeader('ساعات اليوم', boldFont),
                            _pdfHeader('وقت الانصراف', boldFont),
                            _pdfHeader('وقت الحضور', boldFont),
                            _pdfHeader('التاريخ', boldFont),
                            _pdfHeader('اليوم', boldFont),
                          ],
                        ),
                        ...tableRows,
                      ],
                    ),
                    pw.SizedBox(height: 14),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ملاحظات الشهر',
                            style: pw.TextStyle(font: boldFont, fontSize: 11),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            monthlyNote.trim().isEmpty ? '-' : monthlyNote.trim(),
                            style: pw.TextStyle(font: regularFont, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      if (bytes.isEmpty) {
        return const ExportResult(success: false, message: 'ملف PDF الناتج فارغ.');
      }

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'attendance_${DateUtilsAr.monthKey(month)}.pdf',
      );

      return const ExportResult(success: true, message: 'تم تصدير PDF بنجاح');
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'فشل تصدير PDF: $e',
      );
    }
  }

  static Future<void> _ensureFontsLoaded() async {
    if (_regularFont != null && _boldFont != null) return;

    final regularData = await rootBundle.load('assets/static/Alexandria-Regular.ttf');
    final boldData = await rootBundle.load('assets/static/Alexandria-Bold.ttf');

    _regularFont = pw.Font.ttf(regularData);
    _boldFont = pw.Font.ttf(boldData);
  }

  static pw.Widget _pdfHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    );
  }

  static pw.Widget _pdfCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 9),
      ),
    );
  }
}
