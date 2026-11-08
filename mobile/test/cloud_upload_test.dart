import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:attendo/services/cloud_upload_service.dart';
import 'package:attendo_core/utils/app_exception.dart';

void main() {
  final pdf = Uint8List.fromList(List.filled(40 * 1024, 7));

  CloudinaryUploadService service(MockClientStreamHandler handler) => CloudinaryUploadService(
        cloudName: 'demo-cloud',
        uploadPreset: 'attendo_unsigned',
        client: MockClient.streaming(handler),
      );

  test('chưa cấu hình thì báo rõ, không gọi mạng', () async {
    final s = CloudinaryUploadService(cloudName: '', uploadPreset: '');
    expect(s.configured, isFalse);
    await expectLater(
      s.uploadReport(uid: 'u1', fileName: 'a.pdf', bytes: pdf),
      throwsA(isA<AppException>().having((e) => e.message, 'message', 'Chưa cấu hình Cloudinary')),
    );
  });

  test('gửi preset và public_id trong thư mục của uid, trả link và báo tiến độ tới 100%', () async {
    late String sentBody;
    late Uri sentUri;
    final progress = <double>[];
    final s = service((req, body) async {
      sentUri = req.url;
      sentBody = latin1.decode(await body.toBytes());
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({
          'secure_url': 'https://res.cloudinary.com/demo-cloud/raw/upload/v1/attendo/reports/u1/PRM393-SE1801.pdf',
          'public_id': 'attendo/reports/u1/PRM393-SE1801.pdf',
          'bytes': pdf.length,
        }))),
        200,
      );
    });

    final r = await s.uploadReport(uid: 'u1', fileName: 'PRM393 SE1801.pdf', bytes: pdf, onProgress: progress.add);

    expect(sentUri.toString(), 'https://api.cloudinary.com/v1_1/demo-cloud/raw/upload');
    expect(sentBody, contains('attendo_unsigned'));
    expect(sentBody, contains('attendo/reports/u1/PRM393-SE1801.pdf'));
    expect(r.url, startsWith('https://res.cloudinary.com/'));
    expect(r.bytes, pdf.length);
    expect(progress.first, 0);
    expect(progress.last, 1);
  });

  test('tên file lạ bị thay ký tự, thư mục vẫn theo uid', () {
    expect(CloudinaryUploadService.publicIdFor('abc', 'Môn học/1.pdf'), 'attendo/reports/abc/M-n-h-c-1.pdf');
  });

  test('preset sai hoặc bị từ chối thành lỗi có câu ngắn', () {
    expect(
      () => CloudinaryUploadService.parseResponse(400, '{"error":{"message":"Upload preset not found"}}'),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.invalid)),
    );
    expect(
      () => CloudinaryUploadService.parseResponse(401, '{"error":{"message":"Unknown API key"}}'),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.permission)),
    );
    expect(
      () => CloudinaryUploadService.parseResponse(200, '{"public_id":"x"}'),
      throwsA(isA<AppException>()),
    );
  });

  test('mất mạng thành lỗi network', () async {
    final s = service((req, body) async {
      await body.drain<void>();
      throw http.ClientException('Failed host lookup');
    });
    await expectLater(
      s.uploadReport(uid: 'u1', fileName: 'a.pdf', bytes: pdf),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.network)),
    );
  });
}
