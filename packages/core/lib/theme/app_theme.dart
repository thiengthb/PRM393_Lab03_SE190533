import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Màu trạng thái không có chỗ trong ColorScheme: đặt ở ThemeExtension.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.warningSoftEdge,
    required this.danger,
    required this.dangerSoft,
    required this.fgStrong,
    required this.fgDisabled,
    required this.primaryEdge,
    required this.primarySoftEdge,
    required this.camera,
    required this.brand,
    required this.fill,
    required this.fillPressed,
    required this.onFill,
  });

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color warningSoftEdge;
  final Color danger;
  final Color dangerSoft;
  final Color fgStrong;
  final Color fgDisabled;
  final Color primaryEdge;
  final Color primarySoftEdge;
  final Color camera;
  final Color brand;

  /// Nền nút chính, thẻ slot đang diễn ra ([AppPalette.fill]) và chữ trên nền đó.
  final Color fill;
  final Color fillPressed;
  final Color onFill;

  /// Màu trạng thái theo bảng màu [p] ở chế độ sáng hoặc tối.
  factory StatusColors.of(AppPalette p, {bool dark = false}) {
    final n = AppNeutral.of(warm: p.warm, dark: dark);
    final t = dark ? AppTones.dark : AppTones.light;
    final c = p.mode(dark);
    return StatusColors(
      success: t.success,
      successSoft: t.successSoft,
      warning: t.warning,
      warningSoft: t.warningSoft,
      warningSoftEdge: t.warningSoftEdge,
      danger: t.danger,
      dangerSoft: t.dangerSoft,
      fgStrong: n.fg,
      fgDisabled: n.fgDisabled,
      primaryEdge: c.primaryEdge,
      primarySoftEdge: c.primarySoftEdge,
      camera: AppColors.camera,
      brand: p.brand,
      fill: c.fill,
      fillPressed: c.fillPressed,
      onFill: c.onFill,
    );
  }

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) => this;
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
}

/// Tên vai trò của 9 kiểu chữ Lab 2 trên TextTheme (handoff mục 1):
/// display → displaySmall, title-lg → headlineSmall, title → titleMedium,
/// section → titleSmall, body → bodyLarge, body-strong → titleLarge,
/// label → labelLarge, body-sm → bodyMedium, caption → labelSmall.
extension AppTextRoles on TextTheme {
  TextStyle get display => displaySmall!;
  TextStyle get titleLg => headlineSmall!;
  TextStyle get title => titleMedium!;
  TextStyle get section => titleSmall!;
  TextStyle get body => bodyLarge!;
  TextStyle get bodyStrong => titleLarge!;
  TextStyle get label => labelLarge!;
  TextStyle get bodySm => bodyMedium!;
  TextStyle get caption => labelSmall!;
}

abstract final class AppTheme {
  static ColorScheme _scheme(AppPalette p, AppNeutral n, AppTones t, PaletteColors c, bool dark) => ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: c.primary,
    onPrimary: c.onFill,
    primaryContainer: c.primarySoft,
    onPrimaryContainer: c.onPrimarySoft,
    secondary: n.fg,
    onSecondary: n.surface,
    // = --sidebar-accent: nền mục đang chọn ở thanh bên và thanh tab đáy (trung tính).
    secondaryContainer: n.accentStrong,
    onSecondaryContainer: n.fg,
    error: t.danger,
    onError: n.surface,
    errorContainer: t.dangerSoft,
    onErrorContainer: t.danger,
    surface: n.surface,
    onSurface: n.fg,
    onSurfaceVariant: n.fgMuted,
    surfaceContainerLowest: n.bg,
    surfaceContainerLow: n.bg,
    surfaceContainer: n.bg,
    surfaceContainerHigh: n.accent,
    surfaceContainerHighest: n.mutedSurface,
    outline: n.borderControl,
    outlineVariant: n.border,
    scrim: n.scrim,
    inverseSurface: n.fg,
    onInverseSurface: n.bg,
    shadow: AppColors.shadow,
  );

  static TextTheme _textTheme(AppNeutral n) {
    // Onest, một font cho cả app. Tiêu đề chỉ to hơn và khít hơn, cùng màu mực với chữ thân
    // (UI-TASTE.md). Cỡ giữ vừa: tiêu đề màn 20, không phóng to.
    TextStyle s(double size, double height, FontWeight w, Color c, [double tracking = 0]) =>
        TextStyle(
          fontFamily: AppFont.family,
          package: AppFont.package,
          fontSize: size,
          height: height / size,
          fontWeight: w,
          color: c,
          letterSpacing: tracking,
        );
    final strong = n.fg;
    return TextTheme(
      displaySmall: s(24, 30, FontWeight.w600, strong, -0.6),
      headlineSmall: s(20, 26, FontWeight.w600, strong, -0.4),
      titleMedium: s(16, 22, FontWeight.w600, strong, -0.2),
      titleSmall: s(15, 20, FontWeight.w600, strong, -0.1),
      bodyLarge: s(14, 20, FontWeight.w400, n.fg),
      titleLarge: s(14, 20, FontWeight.w500, strong),
      labelLarge: s(14, 20, FontWeight.w500, n.fg),
      bodyMedium: s(13, 18, FontWeight.w400, n.fgMuted),
      labelSmall: s(12, 16, FontWeight.w500, n.fgMuted),
      // Không dùng trên màn, đặt cho đủ để widget Material không lấy cỡ lạ.
      displayLarge: s(24, 30, FontWeight.w600, strong, -0.6),
      displayMedium: s(24, 30, FontWeight.w600, strong, -0.6),
      headlineLarge: s(20, 26, FontWeight.w600, strong, -0.4),
      headlineMedium: s(20, 26, FontWeight.w600, strong, -0.4),
      bodySmall: s(13, 18, FontWeight.w400, n.fgMuted),
      labelMedium: s(12, 16, FontWeight.w500, n.fgMuted),
    );
  }

  /// Theme sáng theo bảng màu [palette] (mặc định Xanh ngọc).
  static ThemeData light([AppPalette palette = AppPalette.teal]) => _build(palette, dark: false);

  /// Theme tối cùng bảng màu: nền than lạnh hoặc ấm theo [AppPalette.warm].
  static ThemeData dark([AppPalette palette = AppPalette.teal]) => _build(palette, dark: true);

  static ThemeData _build(AppPalette p, {required bool dark}) {
    final n = AppNeutral.of(warm: p.warm, dark: dark);
    final t = dark ? AppTones.dark : AppTones.light;
    final c = p.mode(dark);
    final text = _textTheme(n);
    final radius = BorderRadius.circular(AppRadius.md);
    OutlineInputBorder border(Color col, double w) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: col, width: w));
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: _scheme(p, n, t, c, dark),
      textTheme: text,
      fontFamily: AppFont.qualified,
      scaffoldBackgroundColor: n.bg,
      canvasColor: n.bg,
      extensions: [StatusColors.of(p, dark: dark)],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: n.accent.withValues(alpha: 0.6),
      // Đổi trang: mờ dần và trượt nhẹ kiểu Android 14+, iOS giữ cú vuốt của Cupertino.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: n.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: n.fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: n.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s12),
        isDense: true,
        hintStyle: text.bodyLarge!.copyWith(color: n.fgMuted),
        labelStyle: text.labelLarge,
        border: border(n.border, 1),
        enabledBorder: border(n.border, 1),
        focusedBorder: border(c.primary, 1.5),
        errorBorder: border(t.danger, 1),
        focusedErrorBorder: border(t.danger, 1.5),
        disabledBorder: border(n.border, 1),
        errorStyle: text.bodyMedium!.copyWith(color: t.danger),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(dark ? n.fg : n.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.fill : n.fgDisabled,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(c.primary)),
      dividerTheme: DividerThemeData(color: n.border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: n.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: n.border)),
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: n.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        modalBarrierColor: n.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: n.surface,
        contentTextStyle: text.labelLarge!.copyWith(color: n.fg),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.toast),
          side: BorderSide(color: n.border),
        ),
        actionTextColor: c.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: n.mutedSurface,
      ),
      iconTheme: IconThemeData(color: n.fg, size: AppSize.icon24),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: n.fg, borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: text.bodySmall!.copyWith(color: n.bg),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.fill : null),
        checkColor: WidgetStatePropertyAll(c.onFill),
        side: BorderSide(color: n.borderControl, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primarySoftEdge,
        selectionHandleColor: c.primary,
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
