import 'package:flutter/material.dart';

/// Màu không đổi theo bảng màu (Figma v2, kế hoạch giao diện v2 mục 6).
/// Chỉ file trong lib/theme/ được dùng hằng màu; màn hình đọc qua Theme.
/// Các màu đổi theo bảng màu nằm ở [AppPalette].
abstract final class AppColors {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const mutedSurface = Color(0xFFF4F4F4);
  static const border = Color(0xFFE5E5E5); // = color/edge
  static const borderControl = Color(0xFF8F8F8F);
  static const fgStrong = Color(0xFF1F1F1F);
  static const fg = Color(0xFF3C3C3C);
  static const fgMuted = Color(0xFF6B6B6B);
  static const fgDisabled = Color(0xFFAFAFAF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFECFDF3);
  static const warning = Color(0xFFA15C00);
  static const warningSoft = Color(0xFFFFF6DD);

  /// Viền dải vàng (v2). Tương phản chỉ 1,47 nên dải vàng luôn phải có chữ.
  static const warningSoftEdge = Color(0xFFE8CB7F);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEF0EF);
  static const scrim = Color(0x801F1F1F);
  static const camera = Color(0xFF000000);
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
  });

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

  /// Mẫu A, mặc định của Hereby.
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

  /// Thứ tự như khung Chọn màu trên Figma.
  static const all = [bienSau, camFpt, haiQuan, daiDuong, mongKet, cham, man, than];

  static AppPalette byId(String? id) => all.firstWhere((p) => p.id == id, orElse: () => bienSau);
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

abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 8;
  static const double xl = 10;
  static const double toast = 12;
  static const double full = 999;
}

abstract final class AppSize {
  static const double touch = 48;
  static const double buttonInCard = 40;
  static const double buttonInDialog = 36;
  static const double icon20 = 20;
  static const double icon24 = 24;
  static const double avatar = 40;
  static const double badge = 20;
  static const double border = 2;
  static const double ledge = 2;

  /// Bề rộng từ đó web sinh viên đổi sang bố cục laptop (.W).
  static const double wideBreakpoint = 900;
}

/// Font Nunito đóng gói trong `packages/core/fonts` (khai báo ở pubspec của core).
abstract final class AppFont {
  static const family = 'Nunito';
  static const package = 'quick_attend_core';

  /// Tên đầy đủ khi đặt ở ThemeData.fontFamily (không có tham số package).
  static const qualified = 'packages/$package/$family';
}

/// Bố cục màn rộng dùng chung cho app giảng viên bản Windows, web sinh viên và web admin.
abstract final class AppLayout {
  /// Từ bề rộng này trở lên: thanh bên có chữ, lề 24, chữ lớn hơn một bậc.
  static const double wide = 900;

  /// Từ bề rộng nội dung này trở lên thì xếp hai cột.
  static const double twoColumns = 1000;

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
