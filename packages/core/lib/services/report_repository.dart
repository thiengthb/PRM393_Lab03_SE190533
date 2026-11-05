import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_mappers.dart';

/// Metadata file báo cáo: tên, lớp, kích thước và link Cloudinary (file không nằm trong Firestore).
abstract class ReportRepository {
  Future<void> record(String ownerUid, ReportRecord r);
}

class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<void> record(String ownerUid, ReportRecord r) async {
    try {
      await _db.collection('reports').add({
        'ownerUid': ownerUid,
        'classId': r.classId,
        'fileName': r.fileName,
        'sizeKb': r.sizeKb,
        'destination': r.destination,
        if (r.url != null) 'url': r.url,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
