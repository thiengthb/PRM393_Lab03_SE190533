import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import 'package:attendo_core/widgets/widgets.dart';

import '../viewmodels/announcements_viewmodel.dart';
import '../widgets/admin_shell.dart';

/// Form đăng thông báo (ghi `announcements`, hiện ở hộp thư trên app) và danh sách đã đăng.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(announcementsViewModelProvider);
    final vm = ref.read(announcementsViewModelProvider.notifier);
    ref.listen(announcementsViewModelProvider.select((x) => x.message), (prev, next) {
      if (next != null && next != prev) {
        AppToast.show(context, next, error: ref.read(announcementsViewModelProvider).isError);
        vm.messageShown();
      }
    });
    ref.listen(announcementsViewModelProvider.select((x) => x.sentCount), (prev, next) {
      if (prev != null && next != prev) {
        _title.clear();
        _body.clear();
      }
    });

    final form = QaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppTextField(label: 'Tiêu đề', controller: _title, errorText: s.fieldErrors['title']),
        const SizedBox(height: AppSpace.s16),
        AppTextField(label: 'Nội dung', controller: _body, maxLines: 5, errorText: s.fieldErrors['body']),
        const SizedBox(height: AppSpace.s16),
        Text('Gửi tới', style: context.text.label),
        const SizedBox(height: AppSpace.s8),
        AppSegmented<AnnouncementAudience>(
          options: [for (final a in AnnouncementAudience.values) (a, a.label)],
          value: s.audience,
          onChanged: vm.setAudience,
        ),
        const SizedBox(height: AppSpace.s16),
        AppButton(
          label: 'Đăng',
          icon: LucideIcons.send,
          loading: s.sending,
          onPressed: s.sending ? null : () => vm.publish(_title.text, _body.text),
        ),
      ]),
    );

    final list = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Đã đăng', style: context.text.section),
      const SizedBox(height: AppSpace.s8),
      ...switch (s.items) {
        Loading() => const <Widget>[SkeletonList()],
        Failure(:final message) => <Widget>[ErrorState(message: message, onRetry: vm.retry)],
        Empty() => const <Widget>[EmptyState(message: 'Trống', icon: LucideIcons.megaphone)],
        Ready(:final data) => <Widget>[
            for (final a in data) ...[
              SessionRow(
                title: a.archived ? '${a.title} (đã lưu trữ)' : a.title,
                subtitle: '${a.audience.label}${a.publishedAt == null ? '' : ' · ${VnDate.dm(a.publishedAt!)}'}\n${a.body}',
                trailing: AppIconButton(
                  icon: a.archived ? LucideIcons.archiveRestore : LucideIcons.archive,
                  tooltip: a.archived ? 'Đăng lại' : 'Lưu trữ',
                  onPressed: () => vm.setArchived(a, !a.archived),
                ),
              ),
              const SizedBox(height: AppSpace.s8),
            ],
          ],
      },
    ]);

    return AdminPage(
      title: 'Thông báo',
      icon: LucideIcons.megaphone,
      children: [
        LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 760) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [form, const SizedBox(height: AppSpace.group), list]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: form),
            const SizedBox(width: AppSpace.s24),
            Expanded(child: list),
          ]);
        }),
      ],
    );
  }
}
