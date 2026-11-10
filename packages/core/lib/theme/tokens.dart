import 'package:flutter/material.dart';

/// Màu theo thienui (github.com/thiengthb/thienui, `packages/tokens/src/primitive.json`), đổi từ
/// oklch sang sRGB. Nền trung tính có hai nhiệt độ: lạnh (`cool`, đi với màu chủ đạo lạnh như xanh
/// ngọc) và ấm (`warm`, đi với màu ấm như đất nung), mỗi loại có bản sáng và tối (UI-TASTE.md của
/// thienai-workflow). Chỉ file trong lib/theme/ được dùng hằng màu; màn hình đọc qua Theme.
@immutable
class AppNeutral {
  const AppNeutral({
    required this.bg,
    required this.surface,
    required this.mutedSurface,
    required this.accent,
    required this.accentStrong,
    required this.border,
    required this.borderControl,
    required this.fg,
    required this.fgMuted,
    required this.fgDisabled,
    required this.scrim,
  });

  /// = --background (bậc 1). Thẻ, thanh điều hướng, ô nhập dùng [surface] (= --card).
  final Color bg;
  final Color surface;

  /// = --muted (bậc 3): nền tabs, avatar, ô icon.
  final Color mutedSurface;

  /// = --accent (bậc 4): nền khi nhấn; [accentStrong] (bậc 5) = mục đang chọn.
  final Color accent;
  final Color accentStrong;

  /// = --border (bậc 6) và --input (bậc 9 ở nền sáng, 10 ở nền tối).
  final Color border;
  final Color borderControl;

  /// = --foreground (bậc 12): chữ thân và tiêu đề cùng một màu mực; phụ = bậc 11.
  final Color fg;
  final Color fgMuted;
  final Color fgDisabled;
  final Color scrim;

  static const coolLight = AppNeutral(
    bg: Color(0xFFFAFBFD),
    surface: Color(0xFFFFFFFF),
    mutedSurface: Color(0xFFECEFF5),
    accent: Color(0xFFE5EAF0),
    accentStrong: Color(0xFFDFE4EC),
    border: Color(0xFFDBE0E8),
    borderControl: Color(0xFF878E98),
    fg: Color(0xFF131519),
    fgMuted: Color(0xFF5F656D),
    fgDisabled: Color(0xFFC0C7D1),
    scrim: Color(0x80131519),
  );

  static const coolDark = AppNeutral(
    bg: Color(0xFF1B1E21),
    surface: Color(0xFF24272C),
    mutedSurface: Color(0xFF282C31),
    accent: Color(0xFF2E3238),
    accentStrong: Color(0xFF33373D),
    border: Color(0xFF33373D),
    borderControl: Color(0xFF7E848C),
    fg: Color(0xFFF7F9FB),
    fgMuted: Color(0xFF9EA4AB),
    fgDisabled: Color(0xFF4B5058),
    scrim: Color(0xB3000000),
  );

  static const warmLight = AppNeutral(
    bg: Color(0xFFFAF9F5),
    surface: Color(0xFFFFFFFF),
    mutedSurface: Color(0xFFF0EEE6),
    accent: Color(0xFFE9E6DD),
    accentStrong: Color(0xFFE5E2D8),
    border: Color(0xFFE3E1DA),
    borderControl: Color(0xFF918F88),
    fg: Color(0xFF141413),
    fgMuted: Color(0xFF686762),
    fgDisabled: Color(0xFFCAC7BF),
    scrim: Color(0x80141413),
  );

  static const warmDark = AppNeutral(
    bg: Color(0xFF262624),
    surface: Color(0xFF30302E),
    mutedSurface: Color(0xFF343432),
    accent: Color(0xFF3A3A37),
    accentStrong: Color(0xFF3D3D3B),
    border: Color(0xFF3D3D3B),
    borderControl: Color(0xFF878681),
    fg: Color(0xFFFAF9F5),
    fgMuted: Color(0xFFA5A49E),
    fgDisabled: Color(0xFF555552),
    scrim: Color(0xB3000000),
  );

  static AppNeutral of({required bool warm, required bool dark}) =>
      warm ? (dark ? warmDark : warmLight) : (dark ? coolDark : coolLight);
}

/// Màu trạng thái (emerald, amber, rose, blue của thienui): chữ đậm vừa trên nền nhạt kiểu nhãn
/// Notion. Bản tối sáng hơn để đọc được trên nền tối.
@immutable
class AppTones {
  const AppTones({
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.warningSoftEdge,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
  });

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;

  /// Viền dải cảnh báo. Tương phản thấp nên dải luôn phải có chữ.
  final Color warningSoftEdge;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  static const light = AppTones(
    success: Color(0xFF027642),
    successSoft: Color(0xFFE4F4E9),
    warning: Color(0xFF836101),
    warningSoft: Color(0xFFF9EFDA),
    warningSoftEdge: Color(0xFFE9D3A0),
    danger: Color(0xFFC81E3A),
    dangerSoft: Color(0xFFFEE9E9),
    info: Color(0xFF006BAB),
    infoSoft: Color(0xFFE4F2FE),
  );

  static const dark = AppTones(
    success: Color(0xFF47B878),
    successSoft: Color(0xFF1A3122),
    warning: Color(0xFFC69F32),
    warningSoft: Color(0xFF352A12),
    warningSoftEdge: Color(0xFF5A4A20),
    danger: Color(0xFFFE8A8C),
    dangerSoft: Color(0xFF432020),
    info: Color(0xFF54AAEF),
    infoSoft: Color(0xFF182F42),
  );
}

/// Hằng màu bản sáng, nền lạnh: để sinh `design/tokens/attendo.css` cho extension và cho test.
/// Màn hình không đọc các hằng này; chúng đọc qua Theme (sáng hoặc tối).
abstract final class AppColors {
  static const bg = Color(0xFFFAFBFD);
  static const surface = Color(0xFFFFFFFF);
  static const mutedSurface = Color(0xFFECEFF5);
  static const accent = Color(0xFFE5EAF0);
  static const accentStrong = Color(0xFFDFE4EC);
  static const border = Color(0xFFDBE0E8);
  static const borderControl = Color(0xFF878E98);
  static const fgStrong = Color(0xFF131519);
  static const fg = Color(0xFF131519);
  static const fgMuted = Color(0xFF5F656D);
  static const fgDisabled = Color(0xFFC0C7D1);
  static const onPrimary = Color(0xFFFFFFFF);
  static const success = Color(0xFF027642);
  static const successSoft = Color(0xFFE4F4E9);
  static const warning = Color(0xFF836101);
  static const warningSoft = Color(0xFFF9EFDA);
  static const warningSoftEdge = Color(0xFFE9D3A0);
  static const danger = Color(0xFFC81E3A);
  static const dangerSoft = Color(0xFFFEE9E9);
  static const camera = Color(0xFF000000);

  /// Chấm giữa chữ o của logo chữ "attendo": cam FPT, nổi trên vòng màu primary (thien 09/11, D-T-10).
  /// Chỉ là điểm nhấn trang trí, không mang chữ nên không cần tương phản 4,5.
  static const brandDot = Color(0xFFF26F21);
  static const scrim = Color(0x80131519);

  /// Bóng rất nhẹ (elevation 1 của thienui) cho menu, sheet; thẻ thì phẳng.
  static const shadow = Color(0xFF131519);
}

/// Màu của một bảng màu ở một chế độ (sáng hoặc tối).
@immutable
class PaletteColors {
  const PaletteColors({
    required this.primary,
    required this.primaryEdge,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.primarySoftEdge,
    required this.fill,
    required this.fillPressed,
    required this.onFill,
  });

  /// = --accent-brand: chữ, icon, viền ô đang gõ, link.
  final Color primary;

  /// = --press: gờ dưới 2px của nút chính (--lift-primary).
  final Color primaryEdge;

  /// = --brand-wash và bậc soft: nền mục đang chọn, nhãn, và chữ trên nền đó.
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color primarySoftEdge;

  /// = --primary (solid): nền nút chính và thẻ slot đang diễn ra, kèm chữ [onFill].
  final Color fill;
  final Color fillPressed;
  final Color onFill;
}

/// Các bảng màu người dùng chọn ở GV-004 · Màu giao diện. Mỗi bảng có bản sáng và tối, và nói
/// nó đi với nền ấm hay lạnh.
@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.brand,
    required this.light,
    required this.dark,
    this.warm = false,
  });

  /// Khoá lưu trong shared_preferences.
  final String id;

  /// Tên hiện ở khung Chọn màu.
  final String name;

  /// Màu logo và chấm màu ở khung Chọn màu.
  final Color brand;
  final PaletteColors light;
  final PaletteColors dark;

  /// true: nền ngà ấm (thienui `warm`); false: nền trắng lạnh (`cool`).
  final bool warm;

  PaletteColors mode(bool isDark) => isDark ? dark : light;

  // Đọc nhanh bản sáng (extension, test, khung Chọn màu).
  Color get primary => light.primary;
  Color get primaryEdge => light.primaryEdge;
  Color get primarySoft => light.primarySoft;
  Color get onPrimarySoft => light.onPrimarySoft;
  Color get primarySoftEdge => light.primarySoftEdge;
  Color get fill => light.fill;
  Color get onFill => light.onFill;

  /// Slate Teal của thienui, mặc định từ 06/11 đến 09/11/2026 (nay là [fallback] = [banVe], D-T-09).
  /// Nút chính nền xanh ngọc chữ mực như `button.tsx`; tương phản mực trên solid 4,64 (sáng) và 5,88 (tối).
  static const teal = AppPalette(
    id: 'teal',
    name: 'Xanh ngọc',
    brand: Color(0xFF308E84),
    light: PaletteColors(
      primary: Color(0xFF04756B),
      primaryEdge: Color(0xFF0B6961),
      primarySoft: Color(0xFFE4F4F2),
      onPrimarySoft: Color(0xFF04756B),
      primarySoftEdge: Color(0xFFB3E1DA),
      fill: Color(0xFF308E84),
      fillPressed: Color(0xFF1E8177),
      onFill: Color(0xFF131519),
    ),
    dark: PaletteColors(
      primary: Color(0xFF6AC4B8),
      primaryEdge: Color(0xFF1C6B63),
      primarySoft: Color(0xFF182D2A),
      onPrimarySoft: Color(0xFF6AC4B8),
      primarySoftEdge: Color(0xFF234D48),
      fill: Color(0xFF4AA096),
      fillPressed: Color(0xFF60AFA5),
      onFill: Color(0xFF131519),
    ),
  );

  /// "Bản vẽ" (11/2026): xanh cobalt của slide MLN122 (bản vẽ kỹ thuật), để khác các app
  /// cùng lớp đang dùng xanh rêu/ngọc. Tương phản: primary trên nền 6,47; chữ trắng trên fill 6,70;
  /// tối: primary trên nền 7,83, chữ mực trên fill 6,22.
  static const banVe = AppPalette(
    id: 'ban_ve',
    name: 'Bản vẽ',
    brand: Color(0xFF1D4ED8),
    light: PaletteColors(
      primary: Color(0xFF1D4ED8),
      primaryEdge: Color(0xFF1A3FAE),
      primarySoft: Color(0xFFE6EDFD),
      onPrimarySoft: Color(0xFF1D46C4),
      primarySoftEdge: Color(0xFFB6C8F7),
      fill: Color(0xFF1D4ED8),
      fillPressed: Color(0xFF1A43B9),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFF8FB0FF),
      primaryEdge: Color(0xFF2A3F7D),
      primarySoft: Color(0xFF1A2440),
      onPrimarySoft: Color(0xFF8FB0FF),
      primarySoftEdge: Color(0xFF26365F),
      fill: Color(0xFF6F93F3),
      fillPressed: Color(0xFF83A3F6),
      onFill: Color(0xFF131519),
    ),
  );

  /// "Tím" (11/2026): tím violet, sáng hơn Chàm và lạnh hơn Mận. Tương phản: primary trên nền 6,86;
  /// chữ trắng trên fill 7,10; tối: primary trên nền 7,76, chữ mực trên fill 5,78.
  static const tim = AppPalette(
    id: 'tim',
    name: 'Tím',
    brand: Color(0xFF6D28D9),
    light: PaletteColors(
      primary: Color(0xFF6D28D9),
      primaryEdge: Color(0xFF5B21B6),
      primarySoft: Color(0xFFF1EBFE),
      onPrimarySoft: Color(0xFF6225C6),
      primarySoftEdge: Color(0xFFD6C4FB),
      fill: Color(0xFF6D28D9),
      fillPressed: Color(0xFF5B21B6),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFFBBA3FA),
      primaryEdge: Color(0xFF4A3584),
      primarySoft: Color(0xFF261F3B),
      onPrimarySoft: Color(0xFFBBA3FA),
      primarySoftEdge: Color(0xFF372A5B),
      fill: Color(0xFF9E7DF0),
      fillPressed: Color(0xFFAD91F3),
      onFill: Color(0xFF131519),
    ),
  );

  /// Claude Clay của thienui, đi với nền ngà ấm.
  static const clay = AppPalette(
    id: 'clay',
    name: 'Đất nung',
    brand: Color(0xFFD97756),
    warm: true,
    light: PaletteColors(
      primary: Color(0xFFAB4926),
      primaryEdge: Color(0xFFAB5639),
      primarySoft: Color(0xFFFDECE6),
      onPrimarySoft: Color(0xFFAB4926),
      primarySoftEdge: Color(0xFFF9CCBD),
      fill: Color(0xFFD97756),
      fillPressed: Color(0xFFC96948),
      onFill: Color(0xFF141413),
    ),
    dark: PaletteColors(
      primary: Color(0xFFEC8B64),
      primaryEdge: Color(0xFF974A30),
      primarySoft: Color(0xFF3B2923),
      onPrimarySoft: Color(0xFFEC8B64),
      primarySoftEdge: Color(0xFF633C2F),
      fill: Color(0xFFD97756),
      fillPressed: Color(0xFFE58665),
      onFill: Color(0xFF141413),
    ),
  );

  // Các bảng cũ: bản sáng giữ nguyên (chữ trắng trên màu chính). Bản tối suy ra: solid trộn với
  // trắng tới khi mực trên nó >= 5:1, chữ trộn tới khi >= 4,6:1 trên thẻ tối, wash và soft trộn
  // nền tối với màu chính 22% và 42%, gờ dưới trộn solid với nền tối 50%.
  static const xoThom = AppPalette(
    id: 'xo_thom',
    name: 'Xô thơm',
    brand: Color(0xFF386F5F),
    light: PaletteColors(
      primary: Color(0xFF386F5F),
      primaryEdge: Color(0xFF295E4F),
      primarySoft: Color(0xFFEAF7F2),
      onPrimarySoft: Color(0xFF275749),
      primarySoftEdge: Color(0xFFC3DFD5),
      fill: Color(0xFF386F5F),
      fillPressed: Color(0xFF295E4F),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFF9CB7AF),
      primaryEdge: Color(0xFF4C605C),
      primarySoft: Color(0xFF21302F),
      onPrimarySoft: Color(0xFF9CB7AF),
      primarySoftEdge: Color(0xFF27403B),
      fill: Color(0xFF7EA197),
      fillPressed: Color(0xFF8DACA3),
      onFill: Color(0xFF131519),
    ),
  );

  static const bienSau = AppPalette(
    id: 'bien_sau',
    name: 'Biển sâu',
    brand: Color(0xFF0B4F71),
    light: PaletteColors(
      primary: Color(0xFF0B4F71),
      primaryEdge: Color(0xFF07354E),
      primarySoft: Color(0xFFDCEDF5),
      onPrimarySoft: Color(0xFF0A4664),
      primarySoftEdge: Color(0xFF9CC9DF),
      fill: Color(0xFF0B4F71),
      fillPressed: Color(0xFF07354E),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFF85A7B8),
      primaryEdge: Color(0xFF3E5662),
      primarySoft: Color(0xFF172933),
      onPrimarySoft: Color(0xFF85A7B8),
      primarySoftEdge: Color(0xFF143343),
      fill: Color(0xFF608DA3),
      fillPressed: Color(0xFF739BAE),
      onFill: Color(0xFF131519),
    ),
  );

  static const camFpt = AppPalette(
    id: 'cam_fpt',
    name: 'Cam FPT',
    brand: Color(0xFFF26F21),
    warm: true,
    light: PaletteColors(
      primary: Color(0xFFB9551F),
      primaryEdge: Color(0xFF8A3D14),
      primarySoft: Color(0xFFFBEFE8),
      onPrimarySoft: Color(0xFF9A4518),
      primarySoftEdge: Color(0xFFF9B98F),
      fill: Color(0xFFB9551F),
      fillPressed: Color(0xFF8A3D14),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFFDCAA8F),
      primaryEdge: Color(0xFF765747),
      primarySoft: Color(0xFF3E2A21),
      onPrimarySoft: Color(0xFFDCAA8F),
      primarySoftEdge: Color(0xFF5D3520),
      fill: Color(0xFFD2906D),
      fillPressed: Color(0xFFD79D7F),
      onFill: Color(0xFF131519),
    ),
  );

  static const haiQuan = AppPalette(
    id: 'hai_quan',
    name: 'Hải quân',
    brand: Color(0xFF15396F),
    light: PaletteColors(
      primary: Color(0xFF15396F),
      primaryEdge: Color(0xFF0C2549),
      primarySoft: Color(0xFFE1E9F6),
      onPrimarySoft: Color(0xFF15396F),
      primarySoftEdge: Color(0xFFA9BFE0),
      fill: Color(0xFF15396F),
      fillPressed: Color(0xFF0C2549),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFF8A9CB7),
      primaryEdge: Color(0xFF485466),
      primarySoft: Color(0xFF1A2432),
      onPrimarySoft: Color(0xFF8A9CB7),
      primarySoftEdge: Color(0xFF182942),
      fill: Color(0xFF758AAA),
      fillPressed: Color(0xFF8698B4),
      onFill: Color(0xFF131519),
    ),
  );

  static const daiDuong = AppPalette(
    id: 'dai_duong',
    name: 'Đại dương',
    brand: Color(0xFF0B57A4),
    light: PaletteColors(
      primary: Color(0xFF0B57A4),
      primaryEdge: Color(0xFF083D75),
      primarySoft: Color(0xFFDDEBFA),
      onPrimarySoft: Color(0xFF0A4C8F),
      primarySoftEdge: Color(0xFFA3C8EE),
      fill: Color(0xFF0B57A4),
      fillPressed: Color(0xFF083D75),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFF85ABD2),
      primaryEdge: Color(0xFF3E5872),
      primarySoft: Color(0xFF172B3E),
      onPrimarySoft: Color(0xFF85ABD2),
      primarySoftEdge: Color(0xFF143658),
      fill: Color(0xFF6092C4),
      fillPressed: Color(0xFF739FCB),
      onFill: Color(0xFF131519),
    ),
  );

  static const cham = AppPalette(
    id: 'cham',
    name: 'Chàm',
    brand: Color(0xFF3F3A8C),
    light: PaletteColors(
      primary: Color(0xFF3F3A8C),
      primaryEdge: Color(0xFF2B275F),
      primarySoft: Color(0xFFE0DFF2),
      onPrimarySoft: Color(0xFF39347E),
      primarySoftEdge: Color(0xFFA5A1D8),
      fill: Color(0xFF3F3A8C),
      fillPressed: Color(0xFF2B275F),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFF9F9CC6),
      primaryEdge: Color(0xFF50506C),
      primarySoft: Color(0xFF232439),
      onPrimarySoft: Color(0xFF9F9CC6),
      primarySoftEdge: Color(0xFF2A2A4E),
      fill: Color(0xFF8683B7),
      fillPressed: Color(0xFF9592C0),
      onFill: Color(0xFF131519),
    ),
  );

  static const man = AppPalette(
    id: 'man',
    name: 'Mận',
    brand: Color(0xFF6D2E6B),
    light: PaletteColors(
      primary: Color(0xFF6D2E6B),
      primaryEdge: Color(0xFF4A1F49),
      primarySoft: Color(0xFFF1DFF1),
      onPrimarySoft: Color(0xFF622960),
      primarySoftEdge: Color(0xFFD8A2D6),
      fill: Color(0xFF6D2E6B),
      fillPressed: Color(0xFF4A1F49),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFFB696B5),
      primaryEdge: Color(0xFF5F4C62),
      primarySoft: Color(0xFF2D2231),
      onPrimarySoft: Color(0xFFB696B5),
      primarySoftEdge: Color(0xFF3D2540),
      fill: Color(0xFFA37BA2),
      fillPressed: Color(0xFFAE8BAD),
      onFill: Color(0xFF131519),
    ),
  );

  static const than = AppPalette(
    id: 'than',
    name: 'Than',
    brand: Color(0xFF2F3A45),
    light: PaletteColors(
      primary: Color(0xFF2F3A45),
      primaryEdge: Color(0xFF20272F),
      primarySoft: Color(0xFFE4E8EC),
      onPrimarySoft: Color(0xFF2A343E),
      primarySoftEdge: Color(0xFFB0BDC9),
      fill: Color(0xFF2F3A45),
      fillPressed: Color(0xFF20272F),
      onFill: Color(0xFFFFFFFF),
    ),
    dark: PaletteColors(
      primary: Color(0xFF979CA2),
      primaryEdge: Color(0xFF4E5258),
      primarySoft: Color(0xFF1F2429),
      onPrimarySoft: Color(0xFF979CA2),
      primarySoftEdge: Color(0xFF232A30),
      fill: Color(0xFF80878E),
      fillPressed: Color(0xFF8F959C),
      onFill: Color(0xFF131519),
    ),
  );

  /// Bảng màu mặc định (09/11/2026, D-T-09): Bản vẽ. Mọi chỗ cần "màu mặc định" đọc hằng này;
  /// tool/tokens/gen_css.mjs cũng đọc tên ở đây để sinh design/tokens/attendo.css.
  static const fallback = banVe;

  /// Thứ tự trong khung Chọn màu: Bản vẽ mặc định đầu tiên, rồi Tím, Xanh ngọc cũ và các bảng khác.
  static const all = [banVe, tim, teal, clay, xoThom, bienSau, camFpt, haiQuan, daiDuong, cham, man, than];

  static AppPalette byId(String? id) => all.firstWhere((p) => p.id == id, orElse: () => fallback);
}

/// Khoảng cách (lưới 4). Lề màn 12 theo luật chốt Final UI.
abstract final class AppSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  /// Lề trái/phải của mọi màn và thanh nút đáy.
  static const double screen = s12;

  /// Khoảng giữa các nhóm.
  static const double group = s24;
}

/// Bo góc đồng bộ 8px cho nút, ô nhập, thẻ, hộp thoại (UI-TASTE.md, thien duyệt 05/11/2026). Góc
/// lồng nhau dùng bo đồng tâm: trong = ngoài trừ phần đệm ([inner]). Viên thuốc [full] chỉ cho
/// avatar, chấm trạng thái, công tắc.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 8;
  static const double xl = 8;
  static const double toast = 8;
  static const double full = 999;

  /// Bo của hộp nằm trong hộp bo [outer] cách mép [padding] (luật concentric-radius của thienui).
  static double inner(double outer, double padding) => (outer - padding).clamp(2, outer);
}

/// Độ sâu theo thienui: thẻ phẳng có viền; nút nổi bằng một gờ dưới 2px đặc (không mờ), cùng màu
/// viền hoặc màu --press với nút chính. Chỉ menu, sheet, toast có bóng rất nhẹ.
abstract final class AppShadow {
  /// Gờ dưới 2px (--lift / --lift-primary).
  static List<BoxShadow> lift(Color edge) => [BoxShadow(color: edge, offset: const Offset(0, AppSize.lift))];

  /// elevation 2 của thienui: menu, sheet, toast.
  static const raised = [
    BoxShadow(color: Color(0x0D131519), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1F131519), blurRadius: 24, spreadRadius: -12, offset: Offset(0, 8)),
  ];

  /// Giữ tên cũ cho chỗ gọi: thẻ phẳng, không bóng.
  static const List<BoxShadow> card = [];
  static const hairline = BoxShadow(color: Color(0x0D131519), blurRadius: 2, offset: Offset(0, 1));
}

/// Chuyển động theo `motion` của thienui: thời lượng, đường cong vào/ra không đối xứng, và lò xo
/// tính cách `seam` cho thao tác do người dùng bấm. Không chạy chuyển động trên chữ.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
  static const deliberate = Duration(milliseconds: 480);

  static const standard = Cubic(0.2, 0.8, 0.2, 1);
  static const enter = Cubic(0.05, 0.7, 0.1, 1);
  static const exit = Cubic(0.3, 0, 0.8, 0.15);
  static const decelerate = Cubic(0.32, 0.72, 0, 1);

  /// Lò xo `seam`: press (nhấn, gần như tức thì) và snappy (nhả tay, đổi trạng thái).
  static const pressSpring = SpringDescription(mass: 0.5, stiffness: 600, damping: 40);
  static const snappySpring = SpringDescription(mass: 0.7, stiffness: 420, damping: 30);

  /// depth.pressed của thienui.
  static const pressedScale = 0.97;

  /// Danh sách hiện lần lượt khi mở màn: mỗi hàng trễ hơn hàng trước, tối đa [staggerMax] hàng.
  static const stagger = Duration(milliseconds: 35);
  static const staggerMax = 10;
}

abstract final class AppSize {
  static const double touch = 48;
  static const double buttonInCard = 40;
  static const double buttonInDialog = 36;
  static const double icon20 = 20;
  static const double icon24 = 24;
  static const double avatar = 40;
  static const double badge = 20;
  static const double border = 1;

  /// Gờ dưới của nút (--edge-lift).
  static const double lift = 2;
}

/// Font Onest đóng gói trong `packages/core/fonts` (UI-TASTE.md: một font cho cả app, thắng hai lần
/// khi so giấu tên; đủ dấu tiếng Việt).
abstract final class AppFont {
  static const family = 'Onest';
  static const package = 'attendo_core';

  /// Tên đầy đủ khi đặt ở ThemeData.fontFamily (không có tham số package).
  static const qualified = 'packages/$package/$family';
}

/// Bố cục màn rộng dùng chung cho app giảng viên bản Windows, web sinh viên và web admin.
abstract final class AppLayout {
  /// Từ bề rộng này trở lên: thanh bên có chữ, lề 24, chữ lớn hơn một bậc.
  static const double wide = 900;

  /// Từ bề rộng nội dung này trở lên thì xếp hai cột.
  static const double twoColumns = 860;

  /// Thanh bên có chữ / thu gọn chỉ còn icon.
  static const double rail = 240;
  static const double railCollapsed = 72;

  /// Nội dung tối đa: một cột (đọc thoải mái) và cả trang (hai cột, bảng).
  static const double column = 640;
  static const double page = 1200;

  /// Lề trái/phải trên màn rộng (điện thoại vẫn là [AppSpace.screen]).
  static const double screenWide = 24;

  /// Hệ số chữ trên màn rộng: 15 → 16, 13 → 14.
  static const double wideTextScale = 1.07;

  static bool isWide(double width) => width >= wide;
}
