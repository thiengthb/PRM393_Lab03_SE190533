import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:attendo_core/firebase/config_service.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/utils/app_exception.dart';

/// Gợi ý lời nhắc chuyên cần bằng Gemini qua Firebase AI Logic (đề Final mục 8, mức 2).
abstract class AiService {
  Future<ReminderDraft> draftReminder(ReminderInput input, AppRemoteConfig cfg);
}

/// Điền số liệu vào prompt (hàm thuần, có test): chỉ mã môn và con số, không có dữ liệu cá nhân.
String buildReminderPrompt(String template, ReminderInput i) => template
    .replaceAll('{subject}', i.subject)
    .replaceAll('{absent}', '${i.absent}')
    .replaceAll('{limit}', '${i.limit}')
    .replaceAll('{held}', '${i.held}')
    .replaceAll('{total}', '${i.total}');

/// App Check for AI Logic that never blocks a call: when the device cannot get a token
/// (debug build without a registered debug token, or an APK installed outside Play, which
/// fails Play Integrity), the request goes without the header. AI Logic accepts that while
/// App Check stays unenforced; enforcing it would turn these calls into 401s (LOI-15).
class OptionalAppCheck implements FirebaseAppCheck {
  OptionalAppCheck(this._inner);

  final FirebaseAppCheck _inner;

  @override
  Future<String?> getToken([bool? forceRefresh]) async {
    try {
      return await _inner.getToken(forceRefresh);
    } catch (e) {
      debugPrint('App Check token unavailable, calling AI without it: $e');
      return null;
    }
  }

  @override
  Future<String> getLimitedUseToken() => _inner.getLimitedUseToken();

  // firebase_ai only calls the two token methods above; anything else is a programming error.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FirebaseAiService implements AiService {
  FirebaseAiService(this._ai);

  final FirebaseAI _ai;

  static final _schema = Schema.object(
    properties: {
      'tone': Schema.enumString(enumValues: ReminderDraft.tones.toList()),
      'message': Schema.string(description: 'Tối đa 2 câu, không nêu tên người'),
      'next_step': Schema.string(description: 'Một câu về việc sinh viên nên làm tiếp'),
    },
  );

  @override
  Future<ReminderDraft> draftReminder(ReminderInput input, AppRemoteConfig cfg) async {
    try {
      final model = _ai.generativeModel(
        model: cfg.aiModel,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _schema,
          temperature: 0.4,
          maxOutputTokens: 300,
        ),
      );
      final res = await model
          .generateContent([Content.text(buildReminderPrompt(cfg.aiReminderPrompt, input))])
          .timeout(const Duration(seconds: 20));
      final text = res.text;
      if (text == null || text.trim().isEmpty) {
        throw const AppException(AppErrorKind.invalid, 'AI không trả kết quả');
      }
      final json = jsonDecode(text);
      final draft = json is Map<String, Object?> ? ReminderDraft.parse(json) : null;
      if (draft == null) throw const AppException(AppErrorKind.invalid, 'AI trả kết quả không hợp lệ');
      return draft;
    } on AppException {
      rethrow;
    } on QuotaExceeded catch (e) {
      throw AppException(AppErrorKind.quota, 'AI đang hết lượt', cause: e);
    } on FirebaseAIException catch (e) {
      throw AppException(AppErrorKind.unknown, 'AI đang bận', cause: e);
    } on FormatException catch (e) {
      throw AppException(AppErrorKind.invalid, 'AI trả kết quả không hợp lệ', cause: e);
    } catch (e) {
      throw AppException(AppErrorKind.network, 'Không gọi được AI', cause: e);
    }
  }
}
