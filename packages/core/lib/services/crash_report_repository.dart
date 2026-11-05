import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/crash_report.dart';
import 'firestore_mappers.dart';

/// Ghi và đọc `crashReports`. App ghi (chủ tài khoản), chỉ Admin đọc (Security Rules).
abstract class CrashReportRepository {
  Future<void> add(CrashReport r);
  Stream<List<CrashReport>> watchLatest({int limit = 50});
}

class FirestoreCrashReportRepository implements CrashReportRepository {
  FirestoreCrashReportRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('crashReports');

  @override
  Future<void> add(CrashReport r) => _col.add({
        'uid': r.uid,
        'role': r.role,
        'kind': r.kind.id,
        'where': CrashReport.clip(r.where, 80),
        'message': CrashReport.clip(r.message, 500),
        'platform': r.platform,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Stream<List<CrashReport>> watchLatest({int limit = 50}) => Fs.guard(
      _col.orderBy('createdAt', descending: true).limit(limit).snapshots().map((s) => s.docs.map(fromDoc).toList()));

  static CrashReport fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return CrashReport(
      id: d.id,
      uid: m['uid'] as String? ?? '',
      role: m['role'] as String? ?? '',
      kind: CrashKind.from(m['kind'] as String?),
      where: m['where'] as String? ?? '',
      message: m['message'] as String? ?? '',
      platform: m['platform'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
