import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../utils/app_exception.dart';

class PickedFile {
  const PickedFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

abstract class FilePickerService {
  /// null nếu người dùng đóng hộp chọn file.
  Future<PickedFile?> pickImportFile();
}

class SystemFilePickerService implements FilePickerService {
  const SystemFilePickerService();

  @override
  Future<PickedFile?> pickImportFile() async {
    try {
      const group = XTypeGroup(
        label: 'Excel hoặc CSV',
        extensions: ['xlsx', 'csv'],
        mimeTypes: [
          'text/csv',
          'text/comma-separated-values',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ],
        uniformTypeIdentifiers: ['public.comma-separated-values-text', 'org.openxmlformats.spreadsheetml.sheet'],
        webWildCards: ['.csv', '.xlsx'],
      );
      final f = await openFile(acceptedTypeGroups: const [group]);
      if (f == null) return null;
      return PickedFile(f.name, await f.readAsBytes());
    } catch (e) {
      throw AppException(AppErrorKind.permission, 'Không mở được file', cause: e);
    }
  }
}
