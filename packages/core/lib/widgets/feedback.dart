import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'status.dart';

/// Empty state (Figma 5:274): icon trong ô vuông + “Trống” hoặc “Chưa có …” + nút 40 tùy chọn.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = LucideIcons.inbox,
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                icon: LucideIcons.wifiOff,
                background: context.status.dangerSoft,
                color: context.status.danger,
              ),
              const SizedBox(height: AppSpace.s12),
              Text(message, style: context.text.section, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpace.s16),
                AppButton(
                  label: 'Thử lại',
                  icon: LucideIcons.refreshCw,
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
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.colors.outlineVariant, width: AppSize.border),
                ),
              ),
          ],
        ),
      );
}

/// Hộp thoại: bo 12, lề 20, nút cao 36, tối đa 2 nút.
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
          padding: const EdgeInsets.all(AppSpace.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error) ...[
                IconTile(icon: LucideIcons.wifiOff, background: ctx.status.dangerSoft, color: ctx.status.danger, size: 40),
                const SizedBox(height: AppSpace.s12),
              ],
              // Tiêu đề, lời nhắn là node riêng: chữ thường gộp vào node role=dialog thì
              // bản web bỏ mất, trình đọc màn hình chỉ còn đọc hai nút.
              Semantics(header: true, namesRoute: true, child: Text(title, style: ctx.text.title)),
              if (message != null) ...[
                const SizedBox(height: AppSpace.s4),
                Semantics(container: true, child: Text(message, style: ctx.text.body.copyWith(color: ctx.colors.onSurfaceVariant))),
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
              Semantics(header: true, namesRoute: true, child: Text(title, style: ctx.text.title)),
              const SizedBox(height: AppSpace.s12),
              builder(ctx),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toast kiểu sonner: thẻ trắng viền 1, icon xanh (xong) hoặc đỏ (lỗi), chữ mực, “Hoàn tác” màu primary.
abstract final class AppToast {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(BuildContext context, String message,
      {VoidCallback? onUndo, bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    // Màn rộng (web admin, laptop, Windows): toast rộng 420 ở giữa đáy, không kéo hết màn và
    // không đè lên thanh bên.
    final wide = MediaQuery.sizeOf(context).width >= AppLayout.wide;
    return messenger.showSnackBar(
      SnackBar(
        duration: Duration(seconds: onUndo == null ? 3 : 8),
        // Có nút Hoàn tác thì Flutter mặc định giữ toast mãi (persist), nên phải tắt để toast tự ẩn.
        persist: false,
        width: wide ? 420 : null,
        margin: wide ? null : const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.screen),
        content: Semantics(
          liveRegion: true,
          container: true,
          child: Row(
            children: [
              Icon(error ? LucideIcons.circleAlert : LucideIcons.circleCheck, color: error ? context.status.danger : context.status.success, size: AppSize.icon20),
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

/// Khung nội dung chuẩn: lề 12 trên điện thoại, 24 trên màn rộng; giới hạn rộng và đặt giữa.
/// Màn có hai cột thì truyền `maxWidth: AppLayout.page` và dùng [TwoColumns].
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children, this.onRefresh, this.maxWidth = 600, this.padding});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final EdgeInsets? padding;

  static EdgeInsets _defaultPadding(BuildContext context) {
    final side = AppLayout.isWide(MediaQuery.sizeOf(context).width) ? AppLayout.screenWide : AppSpace.screen;
    return EdgeInsets.fromLTRB(side, AppSpace.s16, side, AppSpace.s24);
  }

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? _defaultPadding(context),
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

/// Dải vàng mất mạng (GV-102 .X, GV-001 .X).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.title, required this.detail, required this.onRetry});
  final String title;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: AppSpace.s4),
        decoration: BoxDecoration(
          color: st.warningSoft,
          border: Border.all(color: st.warningSoftEdge),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        constraints: const BoxConstraints(minHeight: 60),
        child: Row(children: [
          Icon(LucideIcons.wifiOff, size: AppSize.icon20, color: st.warning),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.label.copyWith(color: st.fgStrong)),
              Text(detail, style: context.text.bodySm),
            ]),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(AppSize.touch, 44)),
            child: Text(
              'Thử lại',
              style: context.text.label.copyWith(color: st.fgStrong, decoration: TextDecoration.underline),
            ),
          ),
        ]),
      ),
    );
  }
}
