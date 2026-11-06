import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_icons.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../viewmodels/users_viewmodel.dart';
import '../widgets/admin_shell.dart';

/// Chỉ Admin: cấp vai trò. Không đổi được vai trò của chính mình (Rules cũng chặn).
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(usersViewModelProvider);
    final vm = ref.read(usersViewModelProvider.notifier);
    ref.listen(usersViewModelProvider.select((x) => x.message), (prev, next) {
      if (next != null && next != prev) {
        AppToast.show(context, next, error: ref.read(usersViewModelProvider).isError);
        vm.messageShown();
      }
    });
    return AdminPage(
      title: 'Người dùng',
      icon: LucideIcons.userCog,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: AdminSize.searchField, child: AppTextField(hint: 'Tìm tên hoặc email', prefixIcon: LucideIcons.search, onChanged: vm.setQuery)),
        ),
        const SizedBox(height: AppSpace.group),
        ...switch (s.items) {
          Loading() => const <Widget>[SkeletonList()],
          Failure(:final message) => <Widget>[ErrorState(message: message, onRetry: vm.retry)],
          Empty() => const <Widget>[EmptyState(message: 'Không tìm thấy', icon: LucideIcons.userSearch)],
          Ready(:final data) => <Widget>[
              for (final u in data) ...[
                QaCard(
                  semanticsLabel: '${u.displayName}, ${u.role.label}',
                  child: Row(children: [
                    InitialsAvatar(name: u.displayName),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u.displayName, style: context.text.bodyStrong.copyWith(color: context.status.fgStrong)),
                        Text(u.email, style: context.text.bodySm),
                      ]),
                    ),
                    if (u.uid == s.meUid)
                      Text('${u.role.label} · bạn', style: context.text.bodySm)
                    else
                      DropdownButton<UserRole>(
                        value: u.role,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(r.label, style: context.text.label)),
                        ],
                        onChanged: (r) {
                          if (r != null) vm.setRole(u, r);
                        },
                      ),
                  ]),
                ),
                const SizedBox(height: AppSpace.s8),
              ],
            ],
        },
      ],
    );
  }
}
