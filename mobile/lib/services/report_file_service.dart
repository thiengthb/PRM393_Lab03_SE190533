import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'package:attendo_core/utils/app_exception.dart';

/// Lưu PDF vào máy và mở hộp chia sẻ của hệ thống (đề Final mục 4).
abstract class ReportFileService {
  /// Trả đường dẫn đã lưu; web trả tên file vì trình duyệt tự tải xuống.
  Future<String> saveAndShare(String fileName, Uint8List bytes);
}

class DeviceReportFileService implements ReportFileService {
  const DeviceReportFileService();

  @override
  Future<String> saveAndShare(String fileName, Uint8List bytes) async {
    try {
      var saved = fileName;
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        saved = file.path;
      }
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return saved;
    } catch (e) {
      throw AppException(AppErrorKind.unknown, 'Không lưu được file', cause: e);
    }
  }
}
