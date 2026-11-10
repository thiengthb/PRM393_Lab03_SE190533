import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'package:attendo_core/utils/app_exception.dart';

/// Lưu PDF vào máy và mở hộp chia sẻ của hệ thống (đề Final mục 4).
abstract class ReportFileService {
  /// Trả đường dẫn đã lưu; web trả tên file vì trình duyệt tự tải xuống.
  Future<String> saveAndShare(String fileName, Uint8List bytes);

  /// CR-18: tên môn lấy từ file import, có thể chứa `/`, `\`, `..` hay ký tự Windows cấm.
  /// Chỉ thay những ký tự đó bằng `-`, giữ phần còn lại để tên file vẫn đọc được.
  static String safeFileName(String name) {
    var s = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '-').replaceAll('..', '-').trim();
    while (s.startsWith('.')) {
      s = s.substring(1);
    }
    return s.isEmpty ? 'bao-cao.pdf' : s;
  }
}

class DeviceReportFileService implements ReportFileService {
  const DeviceReportFileService();

  @override
  Future<String> saveAndShare(String fileName, Uint8List bytes) async {
    final name = ReportFileService.safeFileName(fileName);
    try {
      var saved = name;
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        saved = file.path;
      }
      await Printing.sharePdf(bytes: bytes, filename: name);
      return saved;
    } catch (e) {
      throw AppException(AppErrorKind.unknown, 'Không lưu được file', cause: e);
    }
  }
}
