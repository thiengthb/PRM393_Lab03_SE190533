import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_mappers.dart';

class DashboardFigures {
  const DashboardFigures({
    required this.pendingClasses,
    required this.approvedClasses,
    required this.students,
    required this.closedSlots,
    required this.present,
    required this.absent,
  });
  final int pendingClasses;
  final int approvedClasses;
  final int students;
  final int closedSlots;
  final int present;
  final int absent;

  int? get presentPercent => present + absent == 0 ? null : (present * 100 / (present + absent)).round();
}

class SubjectRate {
  const SubjectRate({required this.subject, required this.present, required this.absent});
  final String subject;
  final int present;
  final int absent;
  int get total => present + absent;
  double get rate => total == 0 ? 0 : present / total;
}

/// Số liệu Dashboard, đều là aggregation query (không tải từng document).
abstract class DashboardRepository {
  Future<DashboardFigures> figures();
  Future<List<SubjectRate>> rateBySubject(Iterable<String> subjects);
}

class FirestoreDashboardRepository implements DashboardRepository {
  FirestoreDashboardRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<DashboardFigures> figures() async {
    try {
      final classes = _db.collection('classes');
      final pending = classes.where('status', isEqualTo: ClassStatus.pending.name).count().get();
      final approved = classes
          .where('status', isEqualTo: ClassStatus.approved.name)
          .aggregate(count(), sum('studentCount'))
          .get();
      final closed = _db
          .collection('slots')
          .where('closed', isEqualTo: true)
          .aggregate(count(), sum('presentCount'), sum('absentCount'))
          .get();
      final p = await pending;
      final a = await approved;
      final c = await closed;
      return DashboardFigures(
        pendingClasses: p.count ?? 0,
        approvedClasses: a.count ?? 0,
        students: (a.getSum('studentCount') ?? 0).round(),
        closedSlots: c.count ?? 0,
        present: (c.getSum('presentCount') ?? 0).round(),
        absent: (c.getSum('absentCount') ?? 0).round(),
      );
    } catch (e) {
      throw Fs.error(e);
    }
  }

  @override
  Future<List<SubjectRate>> rateBySubject(Iterable<String> subjects) async {
    try {
      final rows = await Future.wait(subjects.map((s) async {
        final r = await _db
            .collection('slots')
            .where('subject', isEqualTo: s)
            .where('closed', isEqualTo: true)
            .aggregate(sum('presentCount'), sum('absentCount'))
            .get();
        return SubjectRate(
          subject: s,
          present: (r.getSum('presentCount') ?? 0).round(),
          absent: (r.getSum('absentCount') ?? 0).round(),
        );
      }));
      return rows.where((r) => r.total > 0).toList()..sort((a, b) => a.rate.compareTo(b.rate));
    } catch (e) {
      throw Fs.error(e);
    }
  }
}
