import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:quick_attend_core/config/app_config.dart';
import 'package:quick_attend_core/utils/app_exception.dart';

/// Kết quả một lần tải file lên đám mây.
class UploadResult {
  const UploadResult({required this.url, required this.publicId, required this.bytes});

  /// Link https để mở hoặc tải file.
  final String url;

  /// Đường dẫn file trong Cloudinary, dạng `hereby/reports/<uid>/<tên file>`.
  final String publicId;
  final int bytes;
}

/// Tải file báo cáo lên đám mây. Thay cho Cloud Storage (gói Spark không có bucket):
/// thầy cho dùng Cloudinary hoặc AWS S3, bản này dùng Cloudinary (D-L3-18).
abstract class CloudUploadService {
  /// false khi bản build chưa có `CLOUDINARY_CLOUD_NAME` và `CLOUDINARY_UPLOAD_PRESET`.
  bool get configured;

  /// Tải [bytes] vào thư mục riêng của người dùng [uid]. [onProgress] nhận 0..1.
  Future<UploadResult> uploadReport({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  });
}

/// Upload thẳng từ app bằng **unsigned upload preset**: app không giữ API secret.
/// Preset trên Cloudinary giới hạn định dạng (pdf), dung lượng và thư mục gốc.
class CloudinaryUploadService implements CloudUploadService {
  CloudinaryUploadService({
    String cloudName = AppConfig.cloudinaryCloudName,
    String uploadPreset = AppConfig.cloudinaryUploadPreset,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  })  : _cloudName = cloudName,
        _preset = uploadPreset,
        _client = client ?? http.Client();

  final String _cloudName;
  final String _preset;
  final http.Client _client;
  final Duration timeout;

  /// Thư mục gốc; mỗi người một thư mục con theo uid, giống `reports/{uid}/…` của đề.
  static String folderFor(String uid) => 'hereby/reports/$uid';

  /// Đường dẫn đầy đủ của file. Thư mục nằm ngay trong public_id (không dùng tham số
  /// `folder`) để đường dẫn giống nhau ở cả hai chế độ thư mục của Cloudinary.
  /// Tên file chỉ giữ chữ, số, `.`, `_`, `-`; raw giữ cả đuôi `.pdf`.
  static String publicIdFor(String uid, String fileName) =>
      '${folderFor(uid)}/${fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-')}';

  @override
  bool get configured => _cloudName.isNotEmpty && _preset.isNotEmpty;

  @override
  Future<UploadResult> uploadReport({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    if (!configured) {
      throw const AppException(AppErrorKind.invalid, 'Chưa cấu hình Cloudinary');
    }
    if (uid.isEmpty) throw AppException.permission;

    // PDF tải lên dạng `raw` để Cloudinary giữ nguyên file, không chuyển thành ảnh.
    final uri = Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/raw/upload');
    final form = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _preset
      ..fields['public_id'] = publicIdFor(uid, fileName)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    // MultipartRequest không báo tiến độ, nên đếm từng khúc byte khi gửi đi.
    final body = form.finalize();
    final total = form.contentLength;
    var sent = 0;
    final request = http.StreamedRequest('POST', uri)
      ..headers.addAll(form.headers)
      ..contentLength = total;
    onProgress?.call(0);
    body.listen(
      (chunk) {
        request.sink.add(chunk);
        sent += chunk.length;
        if (total > 0) onProgress?.call((sent / total).clamp(0, 1).toDouble());
      },
      onDone: request.sink.close,
      onError: (Object e, StackTrace st) => request.sink.addError(e, st),
      cancelOnError: true,
    );

    final http.Response res;
    try {
      res = await http.Response.fromStream(await _client.send(request).timeout(timeout));
    } on TimeoutException catch (e) {
      throw AppException(AppErrorKind.network, 'Tải lên quá lâu, thử lại', cause: e);
    } on http.ClientException catch (e) {
      throw AppException(AppErrorKind.network, 'Mất kết nối mạng', cause: e);
    }
    return parseResponse(res.statusCode, res.body);
  }

  /// Tách riêng để test được mà không cần mạng.
  static UploadResult parseResponse(int status, String body) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw AppException(AppErrorKind.unknown, 'Cloudinary trả về dữ liệu lạ', cause: e);
    }
    if (status >= 200 && status < 300) {
      final url = json['secure_url'];
      if (url is! String || !url.startsWith('https://')) {
        throw const AppException(AppErrorKind.unknown, 'Cloudinary không trả link');
      }
      return UploadResult(
        url: url,
        publicId: '${json['public_id'] ?? ''}',
        bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      );
    }
    final msg = (json['error'] is Map ? json['error']['message'] : null) ?? 'HTTP $status';
    final kind = switch (status) {
      400 => AppErrorKind.invalid,
      401 || 403 => AppErrorKind.permission,
      420 || 429 => AppErrorKind.quota,
      _ => AppErrorKind.unknown,
    };
    final text = switch (kind) {
      AppErrorKind.permission => 'Cloudinary từ chối tải lên',
      AppErrorKind.quota => 'Cloudinary hết hạn mức, thử lại sau',
      AppErrorKind.invalid => 'File hoặc preset không hợp lệ',
      _ => 'Tải lên thất bại',
    };
    throw AppException(kind, text, cause: msg);
  }
}
