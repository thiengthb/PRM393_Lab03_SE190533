import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'status.dart';

/// Empty state (Figma 5:274): icon trong ô vuông + “Trống” hoặc “Chưa có …” + nút 40 tùy chọn.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.detail,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.boxed = true,
  });

  final String message;
  final IconData icon;
  final String? detail;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// true: nằm trong thẻ viền; false: căn giữa màn.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s24, horizontal: AppSpace.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTile(icon: icon),
          const SizedBox(height: AppSpace.s12),
          Text(message, style: context.text.section, textAlign: TextAlign.center),
          if (detail != null) ...[
            const SizedBox(height: AppSpace.s4),
            Text(detail!, style: context.text.bodySm, textAlign: TextAlign.center),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: actionLabel!,
              icon: actionIcon,
              size: AppButtonSize.medium,
              expand: false,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
    if (!boxed) return Center(child: body);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.outlineVariant, width: AppSize.border),
      ),
      child: SizedBox(width: double.infinity, child: body),
    );
  }
}

/// Error state: nguyên nhân bằng lời thường + Thử lại (GV-001 .X).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(
                icon: Icons.wifi_off_rounded,
                background: context.status.dangerSoft,
                color: context.status.danger,
              ),
              const SizedBox(height: AppSpace.s12),
              Text(message, style: context.text.section, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpace.s16),
                AppButton(
                  label: 'Thử lại',
                  icon: Icons.refresh_rounded,
                  size: AppButtonSize.medium,
                  expand: false,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      );
}

/// Skeleton (.L): khối xám theo hình thẻ.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.height = 72});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Đang tải',
        child: Column(
          children: [
            for (var i = 0; i < count; i++)
              Container(
                height: height,
                margin: const EdgeInsets.only(bottom: AppSpace.s12),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
          ],
        ),
      );
}

/// Dialog (Figma 5:259): bo 8, lề 14, nút cao 36, tối đa 2 nút.
abstract final class AppDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String cancelLabel = 'Hủy',
    required String confirmLabel,
    IconData? confirmIcon,
    bool destructive = false,
    bool error = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error) ...[
                IconTile(icon: Icons.wifi_off_rounded, background: ctx.status.dangerSoft, color: ctx.status.danger, size: 40),
                const SizedBox(height: AppSpace.s12),
              ],
              Text(title, style: ctx.text.title),
              if (message != null) ...[
                const SizedBox(height: AppSpace.s4),
                Text(message, style: ctx.text.body.copyWith(color: ctx.colors.onSurfaceVariant)),
              ],
              const SizedBox(height: AppSpace.s16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: cancelLabel,
                      style: AppButtonStyle.outline,
                      size: AppButtonSize.small,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      icon: confirmIcon,
                      style: destructive ? AppButtonStyle.destructive : AppButtonStyle.primary,
                      size: AppButtonSize.small,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

/// Sheet (GV-OV3, GV-OV5): dính đáy, tay nắm 32×4 căn giữa; chạm ngoài để đóng.
abstract final class AppSheet {
  static Future<T?> show<T>(BuildContext context, {required String title, required WidgetBuilder builder}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: context.colors.scrim,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s8, AppSpace.screen, AppSpace.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              Text(title, style: ctx.text.title),
              const SizedBox(height: AppSpace.s12),
              builder(ctx),
            ],
          ),
        ),
      ),
    );
  }
}

/// Snackbar (Figma 5:260): nền color/fg bo 12, tick đặc, chữ trắng, “Hoàn tác” trắng.
abstract final class AppToast {
  static void show(BuildContext context, String message, {VoidCallback? onUndo, bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: Duration(seconds: onUndo == null ? 3 : 8),
        margin: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.screen),
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(error ? Icons.error_rounded : Icons.check_circle_rounded, color: context.colors.onPrimary, size: AppSize.icon20),
              const SizedBox(width: AppSpace.s8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
        action: onUndo == null ? null : SnackBarAction(label: 'Hoàn tác', onPressed: onUndo),
      ),
    );
  }
}

/// Khung nội dung chuẩn: lề 12, giới hạn rộng trên màn lớn.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children, this.onRefresh, this.maxWidth = 600, this.padding});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s8, AppSpace.screen, AppSpace.s24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}
