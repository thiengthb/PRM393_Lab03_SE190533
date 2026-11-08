import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../inbox/inbox_screen.dart';

import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import '../../viewmodels/account_viewmodels.dart';
import '../../viewmodels/lecturer_feed.dart';
import '../../viewmodels/overview_viewmodel.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import 'package:attendo_core/widgets/widgets.dart';

/// GV-001 Tổng quan.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(overviewViewModelProvider);
    final vm = ref.read(overviewViewModelProvider.notifier);
    return Scaffold(
      appBar: const QaAppBar.top(
        title: 'Tổng quan',
        icon: LucideIcons.layoutDashboard,
        actions: [InboxButton()],
      ),
      body: switch (s) {
        Loading() => const ScreenBody(children: [SkeletonList(count: 1, height: 28), SkeletonList(count: 2, height: 80), SkeletonList(count: 3)]),
        Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
        Ready(:final data) => _OverviewBody(data: data),
        Empty() => const SizedBox.shrink(),
      },
    );
  }
}

class _OverviewBody extends ConsumerWidget {
  const _OverviewBody({required this.data});
  final OverviewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final vm = ref.read(overviewViewModelProvider.notifier);
    final offline = ref.watch(lecturerOfflineViewModelProvider);
    String? v(int n) => d.hasClasses ? '$n' : null;
    final wide = context.isWide;
    final stats = [
      (v(d.classCount), 'lớp đang dạy', LucideIcons.bookOpen, null),
      (v(d.studentCount), 'sinh viên', LucideIcons.users, null),
      (
        d.hasClasses ? (d.presentPercent == null ? '—' : '${d.presentPercent}%') : null,
        d.hasClasses && d.presentPercent == null ? 'chưa chốt buổi nào' : 'có mặt tuần này',
        LucideIcons.circleCheck,
        null,
      ),
      (v(d.pendingCount), 'yêu cầu sửa', LucideIcons.pencil, () => context.push('/requests')),
    ];
    final tiles = [for (final (v, l, i, t) in stats) StatTile(value: v, label: l, icon: i, onTap: t)];
    Widget gap(double w) => SizedBox(width: w);
    final statGrid = wide
        ? Row(children: [for (var i = 0; i < tiles.length; i++) ...[if (i > 0) gap(AppSpace.s12), Expanded(child: tiles[i])]])
        : Column(children: [
            Row(children: [Expanded(child: tiles[0]), gap(AppSpace.s12), Expanded(child: tiles[1])]),
            const SizedBox(height: AppSpace.s12),
            Row(children: [Expanded(child: tiles[2]), gap(AppSpace.s12), Expanded(child: tiles[3])]),
          ]);
    final user = ref.watch(accountViewModelProvider).dataOrNull;

    final reviews = [
      for (final c in d.inReview) ...[
        ClassReviewCard(schoolClass: c, onResubmit: () => context.push('/import')),
        const SizedBox(height: AppSpace.s8),
      ],
      if (d.inReview.isNotEmpty) const SizedBox(height: AppSpace.s8),
    ];

    final today = <Widget>[
      // .D3 một slot quên chốt, .D4 nhiều slot quên chốt (mở OV6).
      if (d.unclosed.length == 1) ...[
        _UnclosedStrip(
          title: d.unclosed.single.classLabel,
          detail: '${VnDate.hm(d.unclosed.single.start)}${VnDate.sameDay(d.unclosed.single.start, d.today) ? '' : ' ${VnDate.dm(d.unclosed.single.start)}'} chưa chốt',
          actionLabel: 'Chốt ngay',
          onAction: () => context.push('/session/${d.unclosed.single.id}'),
        ),
        const SizedBox(height: AppSpace.s16),
      ] else if (d.unclosed.length > 1) ...[
        _UnclosedStrip(
          title: '${d.unclosed.length} slot chưa chốt',
          detail: 'Mới nhất ${VnDate.hm(d.unclosed.first.start)} ${VnDate.dm(d.unclosed.first.start)}',
          actionLabel: 'Xem',
          onAction: () => context.push('/unclosed'),
        ),
        const SizedBox(height: AppSpace.s16),
      ],
      if (d.unclosed.isNotEmpty) const SizedBox(height: AppSpace.s8),
      SectionHeader(
        title: 'Vắng nhiều',
        actionLabel: 'Xem tất cả',
        onAction: () => context.push('/attention'),
      ),
      if (d.attention.isEmpty)
        const EmptyState(message: 'Chưa có ai vắng nhiều', icon: LucideIcons.circleCheck)
      else
        CardList(dividerIndent: 64, children: [
          for (final a in d.attention)
            AttentionRow(
              item: a,
              onTap: () => context.push('/student/${a.schoolClass.id}/${a.student.code}'),
            ),
        ]),
    ];

    final calendar = MonthCalendar(
      month: d.month,
      today: d.today,
      dots: d.monthDots,
      slotCount: d.monthSlotCount,
      onShift: vm.shiftMonth,
      onSelect: (day) {
        ref.read(scheduleViewModelProvider.notifier).showDay(day);
        context.go('/schedule');
      },
    );

    return ScreenBody(
      // Màn rộng (Windows, laptop): việc hôm nay bên trái, lịch tháng bên phải.
      maxWidth: wide ? AppLayout.page : 600,
      children: [
        // .X mất mạng: dữ liệu bên dưới là bản lưu trên máy.
        if (offline != null) ...[
          OfflineBanner(
            title: 'Mất mạng',
            detail: switch (offline.lastSync) {
              null => 'Đang xem dữ liệu trên máy',
              final t => 'Dữ liệu lúc ${VnDate.hm(t)}${VnDate.sameDay(t, d.today) ? '' : ' ${VnDate.dm(t)}'}',
            },
            onRetry: ref.read(lecturerOfflineViewModelProvider.notifier).retry,
          ),
          const SizedBox(height: AppSpace.s12),
        ],
        _Hero(
          name: user?.givenName ?? '',
          today: d.today,
          term: d.term,
          slot: d.card,
          phase: d.cardPhase,
          hasClasses: d.hasClasses,
          onOpen: d.card == null ? null : () => context.push('/session/${d.card!.id}'),
        ),
        const SizedBox(height: AppSpace.s16),
        statGrid,
        const SizedBox(height: AppSpace.group),
        ...reviews,
        if (!d.hasClasses && d.inReview.isNotEmpty)
          const SizedBox.shrink()
        else if (!d.hasClasses)
          // .E2 kỳ chưa có lớp.
          EmptyState(
            icon: LucideIcons.calendar,
            message: 'Chưa có lịch',
            detail: 'Hãy nhập danh sách lớp',
            actionLabel: 'Nhập',
            actionIcon: LucideIcons.fileUp,
            onAction: () => context.push('/import'),
          )
        else
          TwoColumns(main: today, side: [calendar], mainFlex: 1, sideFlex: 1),
      ],
    );
  }
}

/// Thẻ đầu trang: lời chào, ngày, kỳ; dưới đường kẻ là slot kế tiếp (hoặc đang diễn ra, chưa chốt)
/// với nút hành động. Thay hàng ngày + thẻ slot riêng của bản Lab 2.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.name,
    required this.today,
    required this.term,
    required this.slot,
    required this.phase,
    required this.hasClasses,
    required this.onOpen,
  });
  final String name;
  final DateTime today;
  final String term;
  final Slot? slot;
  final SlotPhase? phase;
  final bool hasClasses;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final hour = DateTime.now().hour;
    final hello = hour < 11 ? 'Chào buổi sáng' : (hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối');
    final sl = slot;
    final (String tag, String? action, IconData actionIcon) = switch (phase) {
      SlotPhase.live => ('Đang diễn ra', 'Điểm danh', LucideIcons.qrCode),
      SlotPhase.unclosed => ('Chưa chốt', 'Chốt ngay', LucideIcons.check),
      SlotPhase.closed => ('Đã chốt', null, LucideIcons.check),
      _ => (sl != null && VnDate.sameDay(sl.start, today) ? 'Tiếp theo hôm nay' : 'Slot kế tiếp', null, LucideIcons.qrCode),
    };
    final slotRow = sl == null
        ? Row(children: [
            Icon(hasClasses ? LucideIcons.calendarCheck : LucideIcons.fileUp, size: AppSize.icon20, color: c.onSurfaceVariant),
            const SizedBox(width: AppSpace.s12),
            Expanded(child: Text(hasClasses ? 'Không còn slot nào sắp tới' : 'Chưa có lịch dạy', style: context.text.body)),
          ])
        : Row(children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
              decoration: BoxDecoration(
                color: c.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(children: [
                Text(VnDate.hm(sl.start), style: context.text.label.copyWith(color: st.fgStrong, fontWeight: FontWeight.w600)),
                Text('Slot ${sl.slotNo}', style: context.text.caption),
              ]),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sl.classLabel, style: context.text.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${VnDate.range(sl.start, sl.end)} · ${sl.room}', style: context.text.bodySm),
              ]),
            ),
            if (action != null)
              AppButton(label: action, icon: actionIcon, size: AppButtonSize.medium, expand: false, onPressed: onOpen),
          ]);
    final badgeColor = switch (phase) {
      SlotPhase.live => st.danger,
      SlotPhase.unclosed => st.warning,
      _ => c.primary,
    };
    // Thẻ trắng phẳng như card shadcn: đầu thẻ lời chào, dưới đường kẻ là slot kế tiếp.
    return QaCard(
      onTap: sl != null && phase != SlotPhase.upcoming ? onOpen : null,
      kind: CardKind.raised,
      padding: EdgeInsets.zero,
      semanticsLabel: sl == null ? null : '$tag: ${sl.classLabel}, ${VnDate.range(sl.start, sl.end)}, phòng ${sl.room}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.s16, AppSpace.s16, AppSpace.s16, AppSpace.s12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: Text(name.isEmpty ? hello : '$hello, $name', style: context.text.titleLg)),
                const SizedBox(height: 2),
                Text('${VnDate.dayLabel(today)} · $term', style: context.text.bodySm),
              ]),
            ),
          ]),
        ),
        const Divider(height: AppSize.border, thickness: AppSize.border),
        Padding(
          padding: const EdgeInsets.all(AppSpace.s16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (sl != null) ...[
              Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(tag, style: context.text.caption.copyWith(color: st.fgStrong)),
              ]),
              const SizedBox(height: AppSpace.s8),
            ],
            slotRow,
          ]),
        ),
      ]),
    );
  }
}

/// Dải quên chốt (`262:4655`): nền vàng nhạt, luôn có chữ, nút chính bên phải.
class _UnclosedStrip extends StatelessWidget {
  const _UnclosedStrip({required this.title, required this.detail, required this.actionLabel, required this.onAction});
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, AppSpace.s4, AppSpace.s8, AppSpace.s4),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: st.warningSoft,
          border: Border.all(color: st.warningSoftEdge),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(children: [
          Icon(LucideIcons.triangleAlert, size: AppSize.icon20, color: st.warning),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.label.copyWith(color: st.fgStrong, fontWeight: FontWeight.w600)),
              Text(detail, style: context.text.bodySm),
            ]),
          ),
          AppButton(label: actionLabel, style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: onAction),
        ]),
      ),
    );
  }
}

/// GV-OV6 (`307:4982`): danh sách slot chưa chốt, mới nhất trước.
class UnclosedSlotsScreen extends ConsumerWidget {
  const UnclosedSlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(overviewViewModelProvider);
    return Scaffold(
      appBar: const QaAppBar.nested(title: 'Slot chưa chốt', icon: LucideIcons.triangleAlert),
      body: switch (s) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: ref.read(overviewViewModelProvider.notifier).retry),
        Ready(:final data) => ScreenBody(children: [
            if (data.unclosed.isEmpty) const EmptyState(icon: LucideIcons.circleCheck, message: 'Đã chốt hết'),
            for (final slot in data.unclosed) ...[
              Text(VnDate.dayLabel(slot.start), style: context.text.section),
              const SizedBox(height: AppSpace.s8),
              SlotCard(
                slot: slot,
                phase: SlotPhase.unclosed,
                onTap: () => context.push('/session/${slot.id}'),
                onAction: () => context.push('/session/${slot.id}'),
              ),
              const SizedBox(height: AppSpace.s16),
            ],
          ]),
      },
    );
  }
}
