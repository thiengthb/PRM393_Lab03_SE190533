import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/import_models.dart';
import '../utils/app_exception.dart';
import '../utils/calendar.dart';

/// Đọc file Excel/CSV phòng đào tạo gửi thành [ImportPreview] (GV-100).
/// Toàn bộ kiểm tra hợp lệ nằm ở đây, không nằm trong widget.
class ImportService {
  const ImportService();

  static const maxBytes = 5 * 1024 * 1024;
  static const weeksPerTerm = 10;

  /// Cột bắt buộc: mon, lop, mssv, ho_ten. Tùy chọn: email, lich, bat_dau.
  static const template = 'mon,lop,mssv,ho_ten,email,lich,bat_dau\n'
      'PRM393,SE1801,SE190101,Nguyễn Văn An,annv@fpt.edu.vn,T3-S1-P.305;T5-S1-P.305,07/09/2026\n'
      'PRM393,SE1801,SE190114,Trần Thị Bích,bichtt@fpt.edu.vn,,\n'
      'MMA301,SE1805,SE190233,Ngô Bảo Châu,chaunb@fpt.edu.vn,T3-S3-P.402;T4-S1-P.402,07/09/2026\n';

  ImportPreview parse(Uint8List bytes, String fileName, {required DateTime now}) {
    if (bytes.length > maxBytes) {
      throw const AppException(AppErrorKind.invalid, 'File lớn hơn 5 MB');
    }
    final lower = fileName.toLowerCase();
    final List<List<String>> rows;
    if (lower.endsWith('.csv')) {
      rows = parseCsv(utf8.decode(bytes, allowMalformed: true));
    } else if (lower.endsWith('.xlsx')) {
      rows = _readXlsx(bytes);
    } else {
      throw const AppException(AppErrorKind.invalid, 'Chỉ nhận .xlsx hoặc .csv');
    }
    return fromRows(rows, fileName, now: now);
  }

  ImportPreview fromRows(List<List<String>> rows, String fileName, {required DateTime now}) {
    final nonEmpty = rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
    if (nonEmpty.isEmpty) throw const AppException(AppErrorKind.invalid, 'File không có dữ liệu');

    final header = nonEmpty.first.map(_normHeader).toList();
    int col(String name) => header.indexOf(name);
    final iMon = col('mon'), iLop = col('lop'), iMssv = col('mssv'), iName = col('ho_ten');
    final iEmail = col('email'), iLich = col('lich'), iStart = col('bat_dau');
    final missing = [
      if (iMon < 0) 'mon',
      if (iLop < 0) 'lop',
      if (iMssv < 0) 'mssv',
      if (iName < 0) 'ho_ten',
    ];
    if (missing.isNotEmpty) {
      throw AppException(AppErrorKind.invalid, 'Thiếu cột ${missing.join(', ')}');
    }

    final classes = <String, ImportedClass>{};
    final seen = <String, int>{}; // class key + MSSV → dòng đầu tiên
    final errors = <ImportRowError>[];
    String cell(List<String> r, int i) => i >= 0 && i < r.length ? r[i].trim() : '';

    for (var i = 1; i < nonEmpty.length; i++) {
      final r = nonEmpty[i];
      final rowNo = rows.indexOf(r) + 1; // số dòng như Excel
      final subject = cell(r, iMon).toUpperCase();
      final code = cell(r, iLop).toUpperCase();
      final mssv = cell(r, iMssv).toUpperCase();
      final name = cell(r, iName);
      if (subject.isEmpty || code.isEmpty) {
        errors.add(ImportRowError(row: rowNo, message: 'Thiếu mã môn hoặc lớp'));
        continue;
      }
      if (mssv.isEmpty) {
        errors.add(ImportRowError(row: rowNo, message: 'Thiếu MSSV'));
        continue;
      }
      if (!RegExp(r'^[A-Z]{2}\d{6}$').hasMatch(mssv)) {
        errors.add(ImportRowError(row: rowNo, message: 'MSSV $mssv sai định dạng'));
        continue;
      }
      if (name.isEmpty) {
        errors.add(ImportRowError(row: rowNo, message: 'Thiếu họ tên'));
        continue;
      }
      final key = '$subject|$code';
      if (seen.containsKey('$key|$mssv')) {
        errors.add(ImportRowError(row: rowNo, message: 'MSSV $mssv bị trùng'));
        continue;
      }

      final c = classes.putIfAbsent(key, () => ImportedClass(subject: subject, code: code));

      final lich = cell(r, iLich);
      if (lich.isNotEmpty && c.weekly.isEmpty) {
        final parsed = parseSchedule(lich);
        if (parsed == null) {
          errors.add(ImportRowError(row: rowNo, message: 'Lịch sai, ví dụ T3-S1-P.305'));
          continue;
        }
        c.weekly.addAll(parsed);
      }
      final start = cell(r, iStart);
      if (start.isNotEmpty && c.termStart == null) {
        final d = parseDate(start);
        if (d == null) {
          errors.add(ImportRowError(row: rowNo, message: 'Ngày bắt đầu sai, ví dụ 07/09/2026'));
          continue;
        }
        c.termStart = d;
      }
      seen['$key|$mssv'] = rowNo;
      final email = cell(r, iEmail);
      c.students.add(ImportedStudent(code: mssv, name: name, email: email.isEmpty ? null : email));
    }

    for (final c in classes.values) {
      if (c.weekly.isEmpty) {
        errors.add(ImportRowError(row: 0, message: '${c.label} chưa có lịch'));
      }
    }
    final valid = classes.values.where((c) => c.weekly.isNotEmpty && c.students.isNotEmpty).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    final firstStart = valid.map((c) => c.termStart).whereType<DateTime>().fold<DateTime?>(null, (a, b) => a ?? b);
    return ImportPreview(
      fileName: fileName,
      term: Term.of(firstStart ?? now),
      classes: valid,
      errors: errors..sort((a, b) => a.row.compareTo(b.row)),
      weeks: weeksPerTerm,
    );
  }

  /// "T3-S1-P.305;T5-S1-P.305" → 2 slot mỗi tuần.
  static List<WeeklySlot>? parseSchedule(String s) {
    final out = <WeeklySlot>[];
    for (final part in s.split(RegExp(r'[;|]')).map((p) => p.trim()).where((p) => p.isNotEmpty)) {
      final m = RegExp(r'^(T[2-7]|CN)\s*-\s*S(\d)\s*-\s*(.+)$', caseSensitive: false).firstMatch(part);
      if (m == null) return null;
      final wd = VnDate.weekdayFromShort(m.group(1)!);
      final slotNo = int.parse(m.group(2)!);
      if (wd == null || !SlotTimes.isValid(slotNo)) return null;
      out.add(WeeklySlot(weekday: wd, slotNo: slotNo, room: m.group(3)!.trim()));
    }
    return out.isEmpty ? null : out;
  }

  /// dd/MM/yyyy hoặc yyyy-MM-dd (ô ngày của Excel).
  static DateTime? parseDate(String s) {
    final a = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s.trim());
    if (a != null) {
      final d = int.parse(a.group(1)!), m = int.parse(a.group(2)!), y = int.parse(a.group(3)!);
      if (m < 1 || m > 12 || d < 1 || d > 31) return null;
      return DateTime(y, m, d);
    }
    final b = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s.trim());
    if (b != null) return DateTime(int.parse(b.group(1)!), int.parse(b.group(2)!), int.parse(b.group(3)!));
    return null;
  }

  /// CSV có ngoặc kép; tự nhận dấu phân cách “,” hoặc “;” từ dòng đầu.
  static List<List<String>> parseCsv(String text) {
    var t = text;
    if (t.startsWith('﻿')) t = t.substring(1);
    final firstLine = t.split('\n').first;
    final sep = ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length ? ';' : ',';
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < t.length; i++) {
      final ch = t[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < t.length && t[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(ch);
        }
      } else if (ch == '"') {
        quoted = true;
      } else if (ch == sep) {
        row.add(field.toString());
        field.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < t.length && t[i + 1] == '\n') i++;
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(ch);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  List<List<String>> _readXlsx(Uint8List bytes) {
    try {
      final book = Excel.decodeBytes(bytes);
      if (book.tables.isEmpty) return const [];
      final sheet = book.tables[book.tables.keys.first]!;
      return [
        for (final r in sheet.rows) [for (final c in r) cellText(c?.value)],
      ];
    } catch (e) {
      throw AppException(AppErrorKind.invalid, 'Không đọc được file Excel', cause: e);
    }
  }

  /// Chữ của một ô Excel: ô ngày đổi về dd/MM/yyyy, số nguyên không có “.0”.
  static String cellText(CellValue? v) => switch (v) {
        null => '',
        TextCellValue() => v.value.toString(),
        IntCellValue() => '${v.value}',
        DoubleCellValue() => v.value == v.value.roundToDouble() ? '${v.value.toInt()}' : '${v.value}',
        DateCellValue() => '${VnDate.two(v.day)}/${VnDate.two(v.month)}/${v.year}',
        DateTimeCellValue() => '${VnDate.two(v.day)}/${VnDate.two(v.month)}/${v.year}',
        BoolCellValue() => '${v.value}',
        _ => v.toString(),
      };

  static String _normHeader(String h) {
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buf = StringBuffer();
    for (final ch in h.trim().toLowerCase().split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf.toString().replaceAll(RegExp(r'[\s\-]+'), '_').replaceAll('﻿', '');
  }
}
