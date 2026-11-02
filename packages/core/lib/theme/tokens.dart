import 'package:flutter/material.dart';

/// Màu từ biến Figma `Color` (trang 04 Design System, DESIGN.md v3.1).
/// Chỉ file trong lib/theme/ được dùng hằng màu; màn hình đọc qua Theme.
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
  static const primary = Color(0xFFB9551F);
  static const primaryEdge = Color(0xFF8A3D14); // = color/primary-pressed
  static const primarySoft = Color(0xFFFBEFE8);
  static const primarySoftEdge = Color(0xFFF9B98F);
  static const onPrimarySoft = Color(0xFF9A4518);
  static const onPrimary = Color(0xFFFFFFFF);
  static const brand = Color(0xFFF26F21);
  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFECFDF3);
  static const warning = Color(0xFFA15C00);
  static const warningSoft = Color(0xFFFFF6DD);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEF0EF);
  static const scrim = Color(0x801F1F1F);
  static const camera = Color(0xFF000000);
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
