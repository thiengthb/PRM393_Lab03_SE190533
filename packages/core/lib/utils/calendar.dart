/// Kỳ học, giờ slot và định dạng ngày tiếng Việt. Hàm thuần, có unit test.
library;

abstract final class Term {
  /// D-18: tháng 1–4 Spring, 5–8 Summer, 9–12 Fall, kèm năm.
  static String of(DateTime d) {
    final season = d.month <= 4
        ? 'Spring'
        : d.month <= 8
            ? 'Summer'
            : 'Fall';
    return '$season ${d.year}';
  }

  /// Thứ tự để xếp kỳ mới trước kỳ cũ.
  static int sortKey(String term) {
    final parts = term.split(' ');
    if (parts.length != 2) return 0;
    final year = int.tryParse(parts[1]) ?? 0;
    final season = switch (parts[0]) { 'Spring' => 1, 'Summer' => 2, 'Fall' => 3, _ => 0 };
    return year * 10 + season;
  }

  /// Ngày đầu kỳ chứa [d]: 1/1, 1/5, 1/9.
  static DateTime startOf(DateTime d) {
    final m = d.month <= 4
        ? 1
        : d.month <= 8
            ? 5
            : 9;
    return DateTime(d.year, m, 1);
  }
}

/// Khung giờ slot FPTU (giờ địa phương).
abstract final class SlotTimes {
  static const _table = <int, (int, int, int, int)>{
    1: (7, 0, 9, 15),
    2: (9, 30, 11, 45),
    3: (12, 30, 14, 45),
    4: (15, 0, 17, 15),
    5: (17, 30, 19, 45),
    6: (20, 0, 22, 15),
  };

  static bool isValid(int slotNo) => _table.containsKey(slotNo);

  static (DateTime, DateTime) on(DateTime day, int slotNo) {
    final t = _table[slotNo] ?? _table[1]!;
    return (
      DateTime(day.year, day.month, day.day, t.$1, t.$2),
      DateTime(day.year, day.month, day.day, t.$3, t.$4),
    );
  }
}

abstract final class VnDate {
  static const _weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'];
  static const shortWeekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  static String two(int n) => n.toString().padLeft(2, '0');

  /// "Thứ Ba, 20/10"
  static String dayLabel(DateTime d) => '${_weekdays[d.weekday - 1]}, ${two(d.day)}/${two(d.month)}';

  /// "20/10"
  static String dm(DateTime d) => '${two(d.day)}/${two(d.month)}';

  /// "07:00"
  static String hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

  /// "07:00 – 09:15"
  static String range(DateTime a, DateTime b) => '${hm(a)} – ${hm(b)}';

  /// "19/10 – 25/10"
  static String weekRange(DateTime monday) => '${dm(monday)} – ${dm(monday.add(const Duration(days: 6)))}';

  /// "Tháng 10, 2026"
  static String month(DateTime d) => 'Tháng ${d.month}, ${d.year}';

  /// "04:12"
  static String countdown(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    return '${two(s ~/ 60)}:${two(s % 60)}';
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime mondayOf(DateTime d) => dateOnly(d).subtract(Duration(days: d.weekday - 1));

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// "T3" → DateTime.tuesday; null nếu không hợp lệ.
  static int? weekdayFromShort(String s) {
    final i = shortWeekdays.indexOf(s.trim().toUpperCase());
    return i < 0 ? null : i + 1;
  }
}

abstract final class AttendanceMath {
  /// Số buổi được vắng = phần nguyên của [totalSlots] × [percent]%.
  /// 20 slot × 20% = 4 (GV-104 “5/4”, “3/4”).
  static int limit(int totalSlots, int percent) {
    if (totalSlots <= 0) return 0;
    return (totalSlots * percent) ~/ 100;
  }

  /// Phần trăm có mặt, làm tròn. null nếu chưa có buổi nào.
  static int? presentPercent(int present, int absent) {
    final total = present + absent;
    if (total == 0) return null;
    return ((present * 100) / total).round();
  }
}
