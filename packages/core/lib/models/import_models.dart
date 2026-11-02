/// Kết quả đọc file nhập lớp (GV-100 .D1 xem trước, .X dòng lỗi).
class ImportedClass {
  ImportedClass({required this.subject, required this.code});

  final String subject;
  final String code;
  final List<ImportedStudent> students = [];

  /// Lịch tuần: mỗi mục (thứ 1..7 = T2..CN, slot, phòng).
  final List<WeeklySlot> weekly = [];
  DateTime? termStart;

  String get key => '$subject|$code';
  String get label => '$subject · $code';
}

class ImportedStudent {
  const ImportedStudent({required this.code, required this.name, this.email});
  final String code;
  final String name;
  final String? email;
}

class WeeklySlot {
  const WeeklySlot({required this.weekday, required this.slotNo, required this.room});

  /// DateTime.monday (1) … DateTime.sunday (7).
  final int weekday;
  final int slotNo;
  final String room;
}

class ImportRowError {
  const ImportRowError({required this.row, required this.message});

  /// Số dòng như trong Excel (dòng tiêu đề là 1).
  final int row;
  final String message;
}

class ImportPreview {
  const ImportPreview({
    required this.fileName,
    required this.term,
    required this.classes,
    required this.errors,
    required this.weeks,
  });

  final String fileName;
  final String term;
  final List<ImportedClass> classes;
  final List<ImportRowError> errors;
  final int weeks;

  int get weeklySlotCount => classes.fold(0, (n, c) => n + c.weekly.length);
  bool get hasErrors => errors.isNotEmpty;
}
