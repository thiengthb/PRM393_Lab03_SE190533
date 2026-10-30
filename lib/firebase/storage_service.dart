import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../utils/app_exception.dart';

class UploadProgress {
  const UploadProgress(this.fraction, {this.url, this.path});
  final double fraction;
  final String? url;
  final String? path;
  bool get done => url != null;
}

abstract class StorageService {
  /// Tải file lên `reports/{uid}/{fileName}`; luồng báo tiến độ rồi URL.
  Stream<UploadProgress> uploadReport(String uid, String fileName, Uint8List bytes);
}

class FirebaseStorageService implements StorageService {
  FirebaseStorageService(this._s);

  final FirebaseStorage _s;

  @override
  Stream<UploadProgress> uploadReport(String uid, String fileName, Uint8List bytes) async* {
    final ref = _s.ref('reports/$uid/$fileName');
    final task = ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    try {
      await for (final snap in task.snapshotEvents) {
        final total = snap.totalBytes == 0 ? bytes.length : snap.totalBytes;
        if (snap.state == TaskState.success) break;
        yield UploadProgress(total == 0 ? 0 : snap.bytesTransferred / total);
      }
      await task;
      yield UploadProgress(1, url: await ref.getDownloadURL(), path: ref.fullPath);
    } on FirebaseException catch (e) {
      throw switch (e.code) {
        'unauthorized' => AppException(AppErrorKind.permission, 'Không có quyền tải lên', cause: e),
        'canceled' => AppException.cancelled,
        'retry-limit-exceeded' => AppException(AppErrorKind.network, 'Mất kết nối mạng', cause: e),
        _ => AppException(AppErrorKind.unknown, 'Tải lên thất bại', cause: e),
      };
    }
  }
}
