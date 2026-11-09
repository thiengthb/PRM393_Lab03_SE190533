import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/utils/platform.dart';

import 'firebase/ai_service.dart';
import 'firebase/crash_report_sink.dart';
import 'firebase/crash_service.dart';
import 'firebase/local_notification_service.dart';
import 'firebase/messaging_service.dart';
import 'services/cloud_upload_service.dart';
import 'services/file_picker_service.dart';
import 'services/import_service.dart';
import 'services/report_file_service.dart';
import 'services/report_service.dart';

export 'package:attendo_core/providers.dart';

/// Service chỉ có ở app (file, PDF, Cloudinary, Crashlytics, FCM, AI). Phần chung nằm ở core.

final importServiceProvider = Provider<ImportService>((_) => const ImportService());
final reportServiceProvider = Provider<ReportService>((_) => const PdfReportService());
final reportFileServiceProvider = Provider<ReportFileService>((_) => const DeviceReportFileService());
final filePickerServiceProvider = Provider<FilePickerService>((_) => const SystemFilePickerService());

final crashServiceProvider = Provider<CrashService>((ref) => FirebaseCrashService(
      kIsWeb || isDesktop ? null : FirebaseCrashlytics.instance,
      report: ref.watch(crashReportSinkProvider),
    ));
final cloudUploadServiceProvider = Provider<CloudUploadService>((_) => CloudinaryUploadService());
final localNotificationServiceProvider =
    Provider<LocalNotificationService>((_) => FlnLocalNotificationService());
final messagingServiceProvider = Provider<MessagingService>(
    (ref) => FirebaseMessagingService(FirebaseMessaging.instance, ref.watch(localNotificationServiceProvider)));

final aiServiceProvider = Provider<AiService>(
  // App Check token is attached when the device can get one. A sideloaded APK fails Play
  // Integrity, and firebase_ai would then fail the whole call (LOI-15), so the token is optional.
  (_) => FirebaseAiService(FirebaseAI.googleAI(appCheck: OptionalAppCheck(FirebaseAppCheck.instance))),
);
