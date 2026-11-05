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

  factory StatusColors.of(AppPalette p) => StatusColors(
        success: AppColors.success,
        successSoft: AppColors.successSoft,
        warning: AppColors.warning,
        warningSoft: AppColors.warningSoft,
        warningSoftEdge: AppColors.warningSoftEdge,
        danger: AppColors.danger,
        dangerSoft: AppColors.dangerSoft,
        fgStrong: AppColors.fgStrong,
        fgDisabled: AppColors.fgDisabled,
        primaryEdge: p.primaryEdge,
        primarySoftEdge: p.primarySoftEdge,
        camera: AppColors.camera,
        brand: p.brand,
        fill: p.fill,
        fillPressed: p.fillPressed,
        onFill: p.onFill,
      );

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
  static ColorScheme _scheme(AppPalette p) => ColorScheme(
    brightness: Brightness.light,
    primary: p.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: p.primarySoft,
    onPrimaryContainer: p.onPrimarySoft,
    secondary: AppColors.fg,
    onSecondary: AppColors.onPrimary,
    error: AppColors.danger,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.fg,
    onSurfaceVariant: AppColors.fgMuted,
    surfaceContainerLowest: AppColors.bg,
    surfaceContainerLow: AppColors.bg,
    surfaceContainer: AppColors.bg,
    surfaceContainerHigh: AppColors.mutedSurface,
    surfaceContainerHighest: AppColors.mutedSurface,
    outline: AppColors.borderControl,
    outlineVariant: AppColors.border,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.fg,
    onInverseSurface: AppColors.onPrimary,
    shadow: AppColors.shadow,
  );

  static TextTheme _textTheme() {
    // Be Vietnam Pro: chữ to thì khít lại (tracking âm như thang chữ thienui), thân chữ 400.
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
    final base = TextTheme(
      displaySmall: s(28, 34, FontWeight.w700, AppColors.fgStrong, -0.6),
      headlineSmall: s(22, 28, FontWeight.w700, AppColors.fgStrong, -0.3),
      titleMedium: s(17, 24, FontWeight.w600, AppColors.fgStrong, -0.2),
      titleSmall: s(16, 22, FontWeight.w600, AppColors.fgStrong, -0.1),
      bodyLarge: s(15, 22, FontWeight.w400, AppColors.fg),
      titleLarge: s(15, 22, FontWeight.w600, AppColors.fgStrong),
      labelLarge: s(14, 20, FontWeight.w600, AppColors.fg),
      bodyMedium: s(13, 18, FontWeight.w400, AppColors.fgMuted),
      labelSmall: s(12, 16, FontWeight.w500, AppColors.fgMuted),
      // Không dùng trên màn, đặt cho đủ để widget Material không lấy cỡ lạ.
      displayLarge: s(28, 34, FontWeight.w700, AppColors.fgStrong, -0.6),
      displayMedium: s(28, 34, FontWeight.w700, AppColors.fgStrong, -0.6),
      headlineLarge: s(22, 28, FontWeight.w700, AppColors.fgStrong, -0.3),
      headlineMedium: s(22, 28, FontWeight.w700, AppColors.fgStrong, -0.3),
      bodySmall: s(13, 18, FontWeight.w400, AppColors.fgMuted),
      labelMedium: s(12, 16, FontWeight.w500, AppColors.fgMuted),
    );
    return base;
  }

  /// Theme sáng theo bảng màu [palette] (mặc định Teal).
  static ThemeData light([AppPalette palette = AppPalette.teal]) {
    final p = palette;
    final text = _textTheme();
    final radius8 = BorderRadius.circular(AppRadius.md);
    final radius12 = BorderRadius.circular(AppRadius.lg);
    OutlineInputBorder border(Color c, double w) =>
        OutlineInputBorder(borderRadius: radius8, borderSide: BorderSide(color: c, width: w));
    return ThemeData(
      useMaterial3: true,
      colorScheme: _scheme(p),
      textTheme: text,
      fontFamily: AppFont.qualified,
      scaffoldBackgroundColor: AppColors.bg,
      extensions: [StatusColors.of(p)],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.fgStrong,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s12),
        hintStyle: text.bodyLarge!.copyWith(color: AppColors.fgMuted),
        labelStyle: text.labelLarge,
        border: border(AppColors.borderControl, 1),
        enabledBorder: border(AppColors.borderControl, 1),
        focusedBorder: border(p.primary, 2),
        errorBorder: border(AppColors.danger, 1),
        focusedErrorBorder: border(AppColors.danger, 2),
        disabledBorder: border(AppColors.border, 1),
        errorStyle: text.bodyMedium!.copyWith(color: AppColors.danger),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.onPrimary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.fill : AppColors.fgDisabled,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(p.primary)),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius12),
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.fgStrong,
        contentTextStyle: text.labelLarge!.copyWith(color: AppColors.onPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.toast)),
        actionTextColor: AppColors.onPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: AppColors.mutedSurface,
      ),
      iconTheme: const IconThemeData(color: AppColors.fg, size: AppSize.icon24),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.fgStrong, borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: text.bodySmall!.copyWith(color: AppColors.onPrimary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primarySoftEdge,
        selectionHandleColor: p.primary,
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
