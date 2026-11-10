import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/widgets/widgets.dart';

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
    return DeskPage(
      title: 'Người dùng',
      subtitle: 'Chỉ Quản trị đổi được vai trò; không ai đổi vai trò của chính mình',
      actions: [DeskSearchField(hint: 'Tìm tên hoặc email', onChanged: vm.setQuery, width: AdminSize.searchField)],
      body: DeskCard(
        expand: true,
        child: switch (s.items) {
          Loading() => const Padding(padding: EdgeInsets.all(AppSpace.s16), child: SkeletonList(count: 6, height: 40)),
          Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
          Empty() => const EmptyState(message: 'Không tìm thấy', icon: LucideIcons.userSearch, boxed: false),
          Ready(:final data) => DeskTable<AppUser>(
              rows: data,
              rowHeight: 52,
              rowLabel: (u) => '${u.displayName}, ${u.role.label}',
              columns: [
                DeskColumn(
                  label: 'Họ tên',
                  flex: 3,
                  sortBy: (u) => u.displayName,
                  cell: (_, u) => Row(children: [
                    InitialsAvatar(name: u.displayName, size: 30),
                    const SizedBox(width: AppSpace.s12),
                    Flexible(child: Text(u.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                  ]),
                ),
                DeskColumn(label: 'Email', flex: 3, sortBy: (u) => u.email, cell: (ctx, u) => Text(u.email, overflow: TextOverflow.ellipsis, style: ctx.text.caption)),
                DeskColumn(label: 'Mã SV', width: 110, cell: (ctx, u) => Text(u.studentCode ?? '–', style: ctx.text.caption)),
                DeskColumn(
                  label: 'Vai trò',
                  width: 180,
                  sortBy: (u) => u.role.index,
                  cell: (ctx, u) => u.uid == s.meUid
                      ? Text('${u.role.label} · bạn', style: ctx.text.bodySm)
                      : DropdownButton<UserRole>(
                          value: u.role,
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          items: [for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(r.label, style: ctx.text.label))],
                          onChanged: (r) {
                            if (r != null) vm.setRole(u, r);
                          },
                        ),
                ),
              ],
            ),
        },
      ),
    );
  }
}
