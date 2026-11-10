import 'package:shared_preferences/shared_preferences.dart';

/// Lưu bảng màu và chế độ sáng/tối người dùng chọn ở Tài khoản, theo từng máy.
abstract class PaletteStore {
  Future<String?> read();
  Future<void> write(String id);

  /// 'system' | 'light' | 'dark'; null khi chưa chọn (theo máy).
  Future<String?> readMode();
  Future<void> writeMode(String mode);
}

class PrefsPaletteStore implements PaletteStore {
  const PrefsPaletteStore();

  static const _key = 'palette_id_v3'; // v3 (09/11/2026): mọi máy về Bản vẽ mặc định một lần (D-T-09).
  static const _modeKey = 'theme_mode_v1';

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
      // Không lưu được thì lần mở sau dùng lại bảng mặc định; không chặn người dùng.
    }
  }

  @override
  Future<String?> readMode() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_modeKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeMode(String mode) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_modeKey, mode);
    } catch (_) {
      // Không lưu được thì lần mở sau theo máy.
    }
  }
}
