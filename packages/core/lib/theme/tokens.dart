import 'package:flutter/material.dart';

/// Màu không đổi theo bảng màu. Bảng "Teal sâu" (06/11/2026): xám nền và mực ngả cùng sắc teal
/// (OKLCH hue ~195) để cả màn chung một tông; ba màu trạng thái cân cùng độ sáng (L ~0,5). Chỉ file trong lib/theme/ được dùng hằng màu;
/// màn hình đọc qua Theme. Các màu đổi theo bảng màu nằm ở [AppPalette].
abstract final class AppColors {
  /// = --background (cool 1). Thẻ, thanh điều hướng và ô nhập dùng [surface] (= --card) trắng.
  static const bg = Color(0xFFF7FBFB);
  static const surface = Color(0xFFFFFFFF);

  /// = --muted / --sidebar (cool 3): nền tabs, avatar, ô icon, thanh bên.
  static const mutedSurface = Color(0xFFEAF2F2);

  /// = --accent (cool 4): nền khi nhấn trên hàng; [accentStrong] = --sidebar-accent (cool 5), mục đang chọn.
  static const accent = Color(0xFFE3ECEC);
  static const accentStrong = Color(0xFFDBE6E6);
  static const border = Color(0xFFD8E2E2); // --border
  static const borderControl = Color(0xFF96A1A1); // --input
  static const fgStrong = Color(0xFF141C1D); // mực ngả teal
  static const fg = Color(0xFF141C1D); // = --foreground: chữ thân và tiêu đề cùng một màu mực
  static const fgMuted = Color(0xFF616B6C);
  static const fgDisabled = Color(0xFFA2ADAD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const success = Color(0xFF1D7D3E);
  static const successSoft = Color(0xFFE7F7EA);
  static const warning = Color(0xFF945A00); // hổ phách
  static const warningSoft = Color(0xFFFCF0E3);

  /// Viền dải vàng. Tương phản thấp nên dải vàng luôn phải có chữ.
  static const warningSoftEdge = Color(0xFFECCFAE);
  static const danger = Color(0xFFB63039);
  static const dangerSoft = Color(0xFFFFEAE9);
  static const scrim = Color(0x80141C1D);
  static const camera = Color(0xFF000000);

  /// Bóng thẻ (elevation 1 và 2 của thienui): mực, rất nhạt.
  static const shadow = Color(0xFF141C1D);
}

/// Các màu đổi theo bảng màu người dùng chọn ở GV-004 · Chọn màu.
/// Tương phản mẫu Biển sâu: chữ trắng trên primary 8,86; on-primary-soft trên primary-soft 8,43.
@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryEdge,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.primarySoftEdge,
    required this.brand,
    Color? fill,
    Color? fillPressed,
    this.onFill = AppColors.onPrimary,
  }) : fill = fill ?? primary,
       fillPressed = fillPressed ?? primaryEdge;

  /// Khoá lưu trong shared_preferences.
  final String id;

  /// Tên hiện ở khung Chọn màu.
  final String name;
  final Color primary;

  /// = color/primary-pressed, cũng là gờ dưới của nút chính và thẻ bấm được.
  final Color primaryEdge;
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color primarySoftEdge;

  /// Màu logo.
  final Color brand;

  /// Nền nút chính và thẻ slot đang diễn ra. Teal dùng sắc sáng hơn [primary] kèm chữ mực
  /// (như nút của thienui); các mẫu khác = [primary] kèm chữ trắng.
  final Color fill;
  final Color fillPressed;
  final Color onFill;

  /// Mặc định từ 06/11/2026: Teal sâu, một màu teal làm chủ, nút chính chữ trắng.
  /// Tương phản: trắng trên primary 5,6; primary trên nền bg 5,4; on-soft trên soft 7,2.
  static const teal = AppPalette(
    id: 'teal',
    name: 'Teal',
    primary: Color(0xFF00746F),
    primaryEdge: Color(0xFF00625E),
    primarySoft: Color(0xFFE5F8F6),
    onPrimarySoft: Color(0xFF005B57),
    primarySoftEdge: Color(0xFFB5E2DE),
    brand: Color(0xFF00746F),
  );

  /// Mặc định cũ (trước 11/2026).
  static const bienSau = AppPalette(
    id: 'bien_sau',
    name: 'Biển sâu',
    primary: Color(0xFF0B4F71),
    primaryEdge: Color(0xFF07354E),
    primarySoft: Color(0xFFDCEDF5),
    onPrimarySoft: Color(0xFF0A4664),
    primarySoftEdge: Color(0xFF9CC9DF),
    brand: Color(0xFF0B4F71),
  );

  /// Màu cũ của bản Lab 3 đầu (Quick Attend).
  static const camFpt = AppPalette(
    id: 'cam_fpt',
    name: 'Cam FPT',
    primary: Color(0xFFB9551F),
    primaryEdge: Color(0xFF8A3D14),
    primarySoft: Color(0xFFFBEFE8),
    onPrimarySoft: Color(0xFF9A4518),
    primarySoftEdge: Color(0xFFF9B98F),
    brand: Color(0xFFF26F21),
  );

  // Sáu mẫu còn lại của khung Chọn màu (Figma `301:4751`). Hải quân và Đại dương lấy đủ giá trị
  // từ mode "Mẫu B Hải quân", "Mẫu C Đại dương" của bộ biến Color trên Figma. Bốn mẫu sau Figma
  // chỉ cho màu chính; các sắc còn lại suy theo đúng tỉ lệ của Biển sâu trong HSL: pressed = độ
  // sáng x0,68, soft = sáng 91%, on-soft = độ sáng x0,9, soft-edge = sáng 74%. Tương phản: chữ
  // trắng trên primary >= 6,9; on-soft trên soft >= 6,6 (mức cần 4,5).
  static const haiQuan = AppPalette(
    id: 'hai_quan',
    name: 'Hải quân',
    primary: Color(0xFF15396F),
    primaryEdge: Color(0xFF0C2549),
    primarySoft: Color(0xFFE1E9F6),
    onPrimarySoft: Color(0xFF15396F),
    primarySoftEdge: Color(0xFFA9BFE0),
    brand: Color(0xFF15396F),
  );

  static const daiDuong = AppPalette(
    id: 'dai_duong',
    name: 'Đại dương',
    primary: Color(0xFF0B57A4),
    primaryEdge: Color(0xFF083D75),
    primarySoft: Color(0xFFDDEBFA),
    onPrimarySoft: Color(0xFF0A4C8F),
    primarySoftEdge: Color(0xFFA3C8EE),
    brand: Color(0xFF0B57A4),
  );

  static const mongKet = AppPalette(
    id: 'mong_ket',
    name: 'Mòng két',
    primary: Color(0xFF0F6466),
    primaryEdge: Color(0xFF0A4445),
    primarySoft: Color(0xFFDBF4F5),
    onPrimarySoft: Color(0xFF0D5A5C),
    primarySoftEdge: Color(0xFF9CDCDE),
    brand: Color(0xFF0F6466),
  );

  static const cham = AppPalette(
    id: 'cham',
    name: 'Chàm',
    primary: Color(0xFF3F3A8C),
    primaryEdge: Color(0xFF2B275F),
    primarySoft: Color(0xFFE0DFF2),
    onPrimarySoft: Color(0xFF39347E),
    primarySoftEdge: Color(0xFFA5A1D8),
    brand: Color(0xFF3F3A8C),
  );

  static const man = AppPalette(
    id: 'man',
    name: 'Mận',
    primary: Color(0xFF6D2E6B),
    primaryEdge: Color(0xFF4A1F49),
    primarySoft: Color(0xFFF1DFF1),
    onPrimarySoft: Color(0xFF622960),
    primarySoftEdge: Color(0xFFD8A2D6),
    brand: Color(0xFF6D2E6B),
  );

  static const than = AppPalette(
    id: 'than',
    name: 'Than',
    primary: Color(0xFF2F3A45),
    primaryEdge: Color(0xFF20272F),
    primarySoft: Color(0xFFE4E8EC),
    onPrimarySoft: Color(0xFF2A343E),
    primarySoftEdge: Color(0xFFB0BDC9),
    brand: Color(0xFF2F3A45),
  );

  /// Thứ tự trong khung Chọn màu: Teal đầu tiên (mặc định).
  static const all = [teal, bienSau, camFpt, haiQuan, daiDuong, mongKet, cham, man, than];

  static AppPalette byId(String? id) => all.firstWhere((p) => p.id == id, orElse: () => teal);
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

/// Hai mức bo như thienui (nhích lên một chút cho màn cảm ứng): 6 cho nút, ô nhập, tabs; 10 cho thẻ,
/// hộp thoại, sheet. Viên thuốc [full] chỉ cho badge, avatar, công tắc.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 10;
  static const double xl = 10;
  static const double toast = 10;
  static const double full = 999;
}

/// Bóng (elevation thienui). Thẻ chỉ xem không bóng; thẻ bấm được [card]; menu, sheet nổi [raised].
abstract final class AppShadow {
  /// Một nét bóng 1px cho nút viền, ô chọn trên nền xám.
  static const hairline = BoxShadow(color: Color(0x0D131519), blurRadius: 2, offset: Offset(0, 1));
  static const card = [
    BoxShadow(color: Color(0x0D131519), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x14131519), blurRadius: 16, spreadRadius: -8, offset: Offset(0, 6)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x0F131519), blurRadius: 4, spreadRadius: -1, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x29131519), blurRadius: 32, spreadRadius: -12, offset: Offset(0, 12)),
  ];
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
}

/// Font Be Vietnam Pro đóng gói trong `packages/core/fonts` (khai báo ở pubspec của core).
abstract final class AppFont {
  static const family = 'BeVietnamPro';
  static const package = 'quick_attend_core';

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
