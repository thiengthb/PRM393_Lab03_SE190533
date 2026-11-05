import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../inbox/inbox_screen.dart';

import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/models/view_state.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import '../../viewmodels/account_viewmodels.dart';
import '../../viewmodels/lecturer_feed.dart';
import '../../viewmodels/overview_viewmodel.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import 'package:quick_attend_core/widgets/widgets.dart';

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
        icon: Icons.space_dashboard_rounded,
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
      (v(d.classCount), 'lớp đang dạy', Icons.menu_book_outlined, null),
      (v(d.studentCount), 'sinh viên', Icons.group_outlined, null),
      (
        d.hasClasses ? (d.presentPercent == null ? '—' : '${d.presentPercent}%') : null,
        d.hasClasses && d.presentPercent == null ? 'chưa chốt buổi nào' : 'có mặt tuần này',
        Icons.check_circle_outline,
        null,
      ),
      (v(d.pendingCount), 'yêu cầu sửa', Icons.edit_outlined, () => context.push('/requests')),
    ];
    final statGrid = _StatStrip(items: stats, columns: wide ? 4 : 2);
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
        const EmptyState(message: 'Chưa có ai vắng nhiều', icon: Icons.check_circle_outline)
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
            icon: Icons.calendar_today_outlined,
            message: 'Chưa có lịch',
            detail: 'Hãy nhập danh sách lớp',
            actionLabel: 'Nhập',
            actionIcon: Icons.upload_file_outlined,
            onAction: () => context.push('/import'),
          )
        else
          TwoColumns(main: today, side: [calendar], mainFlex: 1, sideFlex: 1),
      ],
    );
  }
}

/// Thẻ đầu trang: lời chào, ngày, kỳ trên nền teal; bên trong là slot kế tiếp (hoặc đang diễn ra,
/// chưa chốt) với nút hành động. Thay hàng ngày + thẻ slot riêng của bản Lab 2.
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
    const ink = Colors.white;
    final hour = DateTime.now().hour;
    final hello = hour < 11 ? 'Chào buổi sáng' : (hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối');
    final sl = slot;
    final (String tag, String? action, IconData actionIcon) = switch (phase) {
      SlotPhase.live => ('Đang diễn ra', 'Điểm danh', Icons.qr_code_2),
      SlotPhase.unclosed => ('Chưa chốt', 'Chốt ngay', Icons.check),
      SlotPhase.closed => ('Đã chốt', null, Icons.check),
      _ => (sl != null && VnDate.sameDay(sl.start, today) ? 'Tiếp theo hôm nay' : 'Slot kế tiếp', null, Icons.qr_code_2),
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg + 4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(st.primaryEdge, st.fgStrong, 0.35)!],
        ),
        boxShadow: AppShadow.card,
      ),
      child: Stack(children: [
        Positioned(
          right: -60,
          top: -70,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ink.withValues(alpha: 0.08), width: 32)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpace.s20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${VnDate.dayLabel(today)} · $term', style: context.text.bodySm.copyWith(color: ink.withValues(alpha: 0.8))),
            const SizedBox(height: AppSpace.s4),
            Semantics(
              header: true,
              child: Text(
                name.isEmpty ? hello : '$hello, $name',
                style: context.text.titleLg.copyWith(color: ink),
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            if (sl == null)
              _HeroPanel(
                child: Row(children: [
                  Icon(hasClasses ? Icons.event_available_outlined : Icons.upload_file_outlined, color: c.primary),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Text(
                      hasClasses ? 'Không còn slot nào sắp tới' : 'Chưa có lịch dạy',
                      style: context.text.bodyStrong,
                    ),
                  ),
                ]),
              )
            else
              _HeroPanel(
                onTap: phase == SlotPhase.upcoming ? null : onOpen,
                semanticsLabel: '$tag: ${sl.classLabel}, ${VnDate.range(sl.start, sl.end)}, phòng ${sl.room}',
                child: Row(children: [
                  Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
                    decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Column(children: [
                      Text(VnDate.hm(sl.start), style: context.text.label.copyWith(color: c.onPrimaryContainer, fontWeight: FontWeight.w700)),
                      Text('Slot ${sl.slotNo}', style: context.text.caption.copyWith(color: c.onPrimaryContainer)),
                    ]),
                  ),
                  const SizedBox(width: AppSpace.s12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        if (phase == SlotPhase.live) ...[
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: st.danger, shape: BoxShape.circle)),
                          const SizedBox(width: AppSpace.s4),
                        ],
                        Flexible(
                          child: Text(
                            tag.toUpperCase(),
                            style: context.text.caption.copyWith(
                              color: phase == SlotPhase.unclosed ? st.warning : c.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(sl.classLabel, style: context.text.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${VnDate.range(sl.start, sl.end)} · ${sl.room}', style: context.text.bodySm),
                    ]),
                  ),
                  if (action != null)
                    AppButton(label: action, icon: actionIcon, size: AppButtonSize.medium, expand: false, onPressed: onOpen),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.child, this.onTap, this.semanticsLabel});
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final panel = Material(
      color: context.colors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(AppSpace.s12), child: child),
      ),
    );
    if (semanticsLabel == null) return panel;
    return Semantics(label: semanticsLabel, button: onTap != null, container: true, child: panel);
  }
}

/// Bốn số trong một thẻ trắng, ngăn bằng đường kẻ (thay bốn ô rời của bản Lab 2).
/// Ô có hành động (yêu cầu sửa) chữ màu primary kèm mũi tên.
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.items, required this.columns});
  final List<(String?, String, IconData, VoidCallback?)> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    Widget cell((String?, String, IconData, VoidCallback?) it) {
      final (value, label, icon, onTap) = it;
      final tappable = onTap != null;
      final fg = tappable ? c.primary : st.fgStrong;
      return Semantics(
        label: '${value ?? 'chưa có'} $label',
        button: tappable,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16, vertical: AppSpace.s12),
            child: Row(children: [
              Icon(icon, size: AppSize.icon20, color: tappable ? c.primary : c.onSurfaceVariant),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(value ?? '—', style: context.text.titleLg.copyWith(color: fg)),
                  Text(label, style: context.text.bodySm.copyWith(color: tappable ? c.primary : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              if (tappable) Icon(Icons.chevron_right, size: AppSize.icon20, color: c.primary),
            ]),
          ),
        ),
      );
    }

    final divider = Container(width: AppSize.border, color: c.outlineVariant);
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      if (i > 0) rows.add(Divider(height: AppSize.border, thickness: AppSize.border, color: c.outlineVariant));
      final chunk = items.sublist(i, (i + columns).clamp(0, items.length));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var j = 0; j < chunk.length; j++) ...[if (j > 0) divider, Expanded(child: cell(chunk[j]))],
        ]),
      ));
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.outlineVariant, width: AppSize.border),
      ),
      child: Material(type: MaterialType.transparency, child: Column(children: rows)),
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
          Icon(Icons.warning_rounded, size: AppSize.icon20, color: st.warning),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.label.copyWith(color: st.fgStrong, fontWeight: FontWeight.w700)),
              Text(detail, style: context.text.bodySm),
            ]),
          ),
          AppButton(label: actionLabel, size: AppButtonSize.medium, expand: false, onPressed: onAction),
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
      appBar: const QaAppBar.nested(title: 'Slot chưa chốt', icon: Icons.warning_rounded),
      body: switch (s) {
        Loading() || Empty() => const ScreenBody(children: [SkeletonList()]),
        Failure(:final message) => ErrorState(message: message, onRetry: ref.read(overviewViewModelProvider.notifier).retry),
        Ready(:final data) => ScreenBody(children: [
            if (data.unclosed.isEmpty) const EmptyState(icon: Icons.check_circle_outline, message: 'Đã chốt hết'),
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
