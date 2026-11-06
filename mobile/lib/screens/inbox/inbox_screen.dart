import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_icons.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

import '../../viewmodels/inbox_viewmodel.dart';

/// Nút hộp thư trên app bar, có chấm khi còn tin chưa đọc.
class InboxButton extends ConsumerWidget {
  const InboxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadProvider);
    return Semantics(
      button: true,
      label: unread == 0 ? 'Hộp thư' : 'Hộp thư, $unread tin chưa đọc',
      onTap: () => context.push('/inbox'),
      container: true,
      excludeSemantics: true,
      child: Stack(alignment: Alignment.center, children: [
        AppIconButton(icon: LucideIcons.mail, tooltip: 'Hộp thư', onPressed: () => context.push('/inbox')),
        if (unread > 0)
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: Container(
                width: AppSpace.s8,
                height: AppSpace.s8,
                decoration: BoxDecoration(color: context.status.danger, shape: BoxShape.circle),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Hộp thư: thông báo từ giáo vụ và kết quả duyệt lớp, cập nhật thời gian thực.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(inboxViewModelProvider.notifier).markRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(inboxViewModelProvider);
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Hộp thư', icon: LucideIcons.mail),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: ref.read(inboxViewModelProvider.notifier).retry),
        Empty() => const ScreenBody(children: [EmptyState(message: 'Trống', icon: LucideIcons.mail)]),
        Ready(:final data) => ScreenBody(children: [
            for (final n in data) ...[
              SessionRow(
                title: n.title,
                subtitle: '${n.body}\n${VnDate.dm(n.at)} ${VnDate.hm(n.at)}',
                onTap: n.route == null ? null : () => context.push(n.route!),
                trailing: n.route == null ? null : const Icon(LucideIcons.chevronRight),
              ),
              const SizedBox(height: AppSpace.s8),
            ],
          ]),
      },
    );
  }
}
