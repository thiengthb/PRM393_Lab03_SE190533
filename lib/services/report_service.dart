import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../utils/calendar.dart';

/// Dữ liệu của báo cáo: đúng những gì GV-103 Chi tiết lớp đang hiện.
class ClassReport {
  const ClassReport({
    required this.schoolClass,
    required this.rows,
    required this.heldSlots,
    required this.limit,
    required this.generatedAt,
    required this.lecturerName,
  });

  final SchoolClass schoolClass;
  final List<StudentAbsence> rows;
  final int heldSlots;
  final int limit;
  final DateTime generatedAt;
  final String lecturerName;
}

abstract class ReportService {
  Future<Uint8List> buildClassReport(ClassReport r);
}

class PdfReportService implements ReportService {
  const PdfReportService();

  @override
  Future<Uint8List> buildClassReport(ClassReport r) async {
    // Font Nunito có đủ dấu tiếng Việt; tải lần đầu rồi printing tự lưu đệm.
    pw.ThemeData theme;
    try {
      theme = pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
      );
    } catch (_) {
      theme = pw.ThemeData.base();
    }
    const primary = PdfColor.fromInt(0xFFB9551F);
    const danger = PdfColor.fromInt(0xFFB42318);
    const warning = PdfColor.fromInt(0xFFA15C00);
    const muted = PdfColor.fromInt(0xFF6B6B6B);
    const border = PdfColor.fromInt(0xFFE5E5E5);

    final c = r.schoolClass;
    final doc = pw.Document(title: 'Chuyên cần ${c.label}', author: r.lecturerName);
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Row(children: [
          pw.Text('Quick Attend', style: pw.TextStyle(color: primary, fontWeight: pw.FontWeight.bold)),
          pw.Spacer(),
          pw.Text('${VnDate.dayLabel(r.generatedAt)} ${VnDate.hm(r.generatedAt)}', style: const pw.TextStyle(color: muted)),
        ]),
        build: (_) => [
          pw.SizedBox(height: 12),
          pw.Text(c.code, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text('${c.subject} · ${c.term} · ${r.lecturerName}', style: const pw.TextStyle(color: muted)),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            _stat('${c.studentCount}', 'sinh viên'),
            pw.SizedBox(width: 12),
            _stat('${r.heldSlots}/${c.totalSlots}', 'buổi đã học'),
            pw.SizedBox(width: 12),
            _stat('${r.limit}', 'buổi được vắng'),
          ]),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['MSSV', 'Họ tên', 'Vắng', 'Mức'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: border)),
            cellAlignments: {2: pw.Alignment.centerRight, 3: pw.Alignment.centerLeft},
            data: [
              for (final a in r.rows)
                [
                  a.student.code,
                  a.student.name,
                  '${a.absent}/${a.limit}',
                  switch (a.level) {
                    AbsenceLevel.over => 'Quá ngưỡng',
                    AbsenceLevel.near => 'Sắp chạm',
                    AbsenceLevel.ok => '',
                  },
                ],
            ],
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellDecoration: (index, data, rowNum) {
              if (index != 3) return const pw.BoxDecoration();
              final over = data == 'Quá ngưỡng';
              final near = data == 'Sắp chạm';
              if (!over && !near) return const pw.BoxDecoration();
              return pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: over ? danger : warning, width: 3)));
            },
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _stat(String value, String label) => pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E5E5), width: 2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF6B6B6B))),
        ]),
      );
}
