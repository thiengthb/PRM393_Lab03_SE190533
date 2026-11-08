import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_icons.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import '../../viewmodels/account_viewmodels.dart';
import '../../viewmodels/app_viewmodel.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

/// GV-004 Tài khoản v2 (`308:5155`, + .C hộp thoại Đăng xuất, nhóm Firebase D-L3-04).
/// Dùng lại cho tài khoản sinh viên SV-003 (`308:5363`): ẩn Nhắc nhở, Màu giao diện và Dữ liệu.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key, this.nested = false});

  /// true: mở từ web sinh viên (có nút quay lại).
  final bool nested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(accountViewModelProvider);
    final vm = ref.read(accountViewModelProvider.notifier);
    final palette = ref.watch(paletteViewModelProvider);
    return Scaffold(
      appBar: nested
          ? const QaAppBar.nested(title: 'Tài khoản', icon: LucideIcons.user)
          : const QaAppBar.top(title: 'Tài khoản', icon: LucideIcons.user),
      body: switch (s) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList(count: 3)]),
        Failure(:final message) => ErrorState(message: message),
        Ready(:final data) => ScreenBody(
            children: [
              // Hồ sơ là thẻ chìm: chỉ để xem.
              QaCard(
                kind: CardKind.sunken,
                child: Row(children: [
                  InitialsAvatar(name: data.displayName),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data.displayName, style: context.text.body.copyWith(color: context.status.fgStrong)),
                      Text(
                        data.studentCode == null ? data.email : '${data.studentCode} · ${data.email}',
                        style: context.text.bodySm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpace.group),
              if (data.role == UserRole.lecturer) ...[
                const _GroupTitle('Nhắc nhở'),
                _Group(children: [
                  _SwitchRow(
                    icon: LucideIcons.bell,
                    title: 'Trước slot',
                    detail: '10 phút',
                    value: data.reminderBeforeSlot,
                    onChanged: vm.setBeforeSlot,
                  ),
                  _SwitchRow(
                    icon: LucideIcons.clock,
                    title: 'Slot chưa chốt',
                    detail: 'Khi hết giờ',
                    value: data.reminderUnclosed,
                    onChanged: vm.setUnclosed,
                  ),
                ]),
                const SizedBox(height: AppSpace.group),
              ],
              // Giao diện: ai cũng chọn được Sáng/Tối/Theo máy; màu chủ đạo chỉ giảng viên.
              const _GroupTitle('Giao diện'),
              _Group(children: [
                _ModeRow(
                  value: ref.watch(themeModeViewModelProvider),
                  onChanged: ref.read(themeModeViewModelProvider.notifier).select,
                ),
                if (data.role == UserRole.lecturer)
                  _LinkRow(
                    leading: _Dot(color: palette.brand, size: 20),
                    title: 'Màu giao diện',
                    detail: palette.name,
                    onTap: () => _pickPalette(context, ref),
                  ),
              ]),
              const SizedBox(height: AppSpace.group),
              const _GroupTitle('Giáo vụ'),
              _Group(children: [
                _LinkRow(
                  leading: const Icon(LucideIcons.mail),
                  title: 'Hộp thư',
                  detail: 'Thông báo từ giáo vụ',
                  onTap: () => context.push('/inbox'),
                ),
              ]),
              const SizedBox(height: AppSpace.group),
              const _GroupTitle('Firebase'),
              _Group(children: [
                _LinkRow(
                  leading: const Icon(LucideIcons.bell),
                  title: 'Thông báo',
                  detail: 'Tin FCM đã nhận',
                  onTap: () => context.push('/notifications'),
                ),
                _LinkRow(
                  leading: const Icon(LucideIcons.layoutDashboard),
                  title: 'Khu demo',
                  detail: 'Xuất báo cáo, Remote Config, Crashlytics',
                  onTap: () => context.push('/demo'),
                ),
              ]),
              const SizedBox(height: AppSpace.group),
              if (data.role == UserRole.lecturer) ...[
                const _GroupTitle('Dữ liệu'),
                _Group(children: [
                  _LinkRow(
                    leading: const Icon(LucideIcons.download),
                    title: 'Nhập danh sách lớp',
                    detail: data.lastImportAt == null ? 'Chưa nhập' : 'Lần cuối ${VnDate.dm(data.lastImportAt!)}',
                    onTap: () => context.push('/import'),
                  ),
                ]),
                const SizedBox(height: AppSpace.group),
              ],
              // Đăng xuất tách riêng một thẻ, chữ và icon đỏ.
              _Group(children: [
                _LinkRow(
                  leading: Icon(LucideIcons.logOut, color: context.status.danger),
                  leadingBackground: context.status.dangerSoft,
                  title: 'Đăng xuất',
                  titleColor: context.status.danger,
                  chevron: false,
                  onTap: () async {
                    final ok = await AppDialog.confirm(
                      context,
                      title: 'Đăng xuất?',
                      message: data.email,
                      confirmLabel: 'Đăng xuất',
                      destructive: true,
                    );
                    if (ok) await vm.signOut();
                  },
                ),
              ]),
            ],
          ),
      },
    );
  }

  /// Khung Chọn màu (`301:4751`). Chỉ hiện bảng màu đã làm được (D-L3-12).
  void _pickPalette(BuildContext context, WidgetRef ref) {
    final current = ref.read(paletteViewModelProvider);
    AppSheet.show<void>(
      context,
      title: 'Màu giao diện',
      builder: (ctx) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpace.s8,
        crossAxisSpacing: AppSpace.s8,
        childAspectRatio: 3.4,
        children: [
          for (final p in AppPalette.all)
            Semantics(
              button: true,
              selected: p.id == current.id,
              label: 'Màu ${p.name}',
              onTap: () {
                ref.read(paletteViewModelProvider.notifier).select(p);
                Navigator.of(ctx).pop();
              },
              container: true,
              excludeSemantics: true,
              child: Material(
                color: p.id == current.id ? ctx.colors.primaryContainer : ctx.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    ref.read(paletteViewModelProvider.notifier).select(p);
                    Navigator.of(ctx).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
                    child: Row(children: [
                      _Dot(color: p.brand, size: 12),
                      const SizedBox(width: AppSpace.s12),
                      Text(p.name, style: ctx.text.body.copyWith(color: ctx.status.fgStrong)),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.s12),
        child: Text(text, style: context.text.section),
      );
}

/// Nhóm hàng trong một thẻ nổi, ngăn bằng đường kẻ (GV-004 v2).
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => QaCard(
        kind: CardKind.raised,
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: AppSpace.s12, endIndent: AppSpace.s12, color: context.colors.outlineVariant),
            children[i],
          ],
        ]),
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _Leading extends StatelessWidget {
  const _Leading({required this.child, this.background});
  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: IconTheme(data: IconThemeData(size: AppSize.icon20, color: context.colors.onSurfaceVariant), child: child),
      );
}

/// Chế độ sáng/tối: ba ô Theo máy · Sáng · Tối.
class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.value, required this.onChanged});
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpace.s12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const _Leading(child: Icon(LucideIcons.sunMoon)),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Chế độ', style: context.text.body.copyWith(color: context.status.fgStrong)),
                Text('Sáng, tối hoặc theo cài đặt của máy', style: context.text.bodySm),
              ]),
            ),
          ]),
          const SizedBox(height: AppSpace.s12),
          AppSegmented<ThemeMode>(
            options: const [(ThemeMode.system, 'Theo máy'), (ThemeMode.light, 'Sáng'), (ThemeMode.dark, 'Tối')],
            value: value,
            onChanged: onChanged,
          ),
        ]),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.icon, required this.title, required this.detail, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s8),
          child: Row(children: [
            _Leading(child: Icon(icon)),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: context.text.body.copyWith(color: context.status.fgStrong)),
                Text(detail, style: context.text.bodySm),
              ]),
            ),
            AppSwitch(value: value, onChanged: onChanged),
          ]),
        ),
      );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.leading,
    required this.title,
    required this.onTap,
    this.detail,
    this.leadingBackground,
    this.titleColor,
    this.chevron = true,
  });
  final Widget leading;
  final Color? leadingBackground;
  final String title;
  final String? detail;
  final Color? titleColor;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: detail == null ? title : '$title, $detail',
        onTap: onTap,
        container: true,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s8),
              child: Row(children: [
                _Leading(background: leadingBackground, child: leading),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: context.text.body.copyWith(color: titleColor ?? context.status.fgStrong)),
                    if (detail != null) Text(detail!, style: context.text.bodySm, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                if (chevron) Icon(LucideIcons.chevronRight, color: context.status.fgStrong),
              ]),
            ),
          ),
        ),
      );
}
