import 'package:shared_preferences/shared_preferences.dart';

/// Lưu bảng màu người dùng chọn ở GV-004 · Chọn màu, theo từng máy.
abstract class PaletteStore {
  Future<String?> read();
  Future<void> write(String id);
}

class PrefsPaletteStore implements PaletteStore {
  const PrefsPaletteStore();

  static const _key = 'palette_id_v2'; // v2 (11/2026): mọi máy về Teal mặc định một lần.

  @override
  Future<String?> read() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String id) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, id);
    } catch (_) {
      // Không lưu được thì lần mở sau dùng lại Biển sâu; không chặn người dùng.
    }
  }
}
