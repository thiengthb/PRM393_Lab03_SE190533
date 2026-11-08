import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/theme/app_icons.dart';
import 'package:attendo_core/theme/app_theme.dart';
import 'package:attendo_core/theme/tokens.dart';
import 'package:attendo_core/utils/calendar.dart';
import 'package:attendo_core/widgets/widgets.dart';
import '../../../viewmodels/account_viewmodels.dart';
import '../../../viewmodels/lecturer_feed.dart';
import '../../../viewmodels/overview_viewmodel.dart';
import '../../inbox/inbox_screen.dart';

/// GV-001 Tổng quan, desktop (direction A chosen 09/11): the class happening now on top,
/// "Việc cần xử lý" and the next 7 days below. Same [OverviewViewModel] as the phone screen.
class OverviewDesktop extends ConsumerWidget {
  const OverviewDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(overviewViewModelProvider);
    final vm = ref.read(overviewViewModelProvider.notifier);
    final user = ref.watch(accountViewModelProvider).dataOrNull;
    final offline = ref.watch(lecturerOfflineViewModelProvider);
    final hour = DateTime.now().hour;
    final hello = hour < 11 ? 'Chào buổi sáng' : (hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối');
    final d = s.dataOrNull;
    final card = d?.card;
    final open = card != null && (d?.cardPhase == SlotPhase.live || d?.cardPhase == SlotPhase.unclosed);
    return DeskShortcuts(
      bindings: {
        if (open) const SingleActivator(LogicalKeyboardKey.keyD, control: true): () => context.push('/session/${card.id}'),
      },
      child: DeskPage(
        title: user == null ? hello : '$hello, ${user.givenName}',
        subtitle: d == null ? null : '${VnDate.dayLabel(d.today)} · ${d.term}',
        actions: const [InboxButton()],
        scroll: true,
        maxWidth: 1400,
        banner: offline == null
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.s20, AppSpace.s12, AppSpace.s20, 0),
                child: OfflineBanner(
                  title: 'Mất mạng',
                  detail: offline.lastSync == null ? 'Đang xem dữ liệu trên máy' : 'Dữ liệu lúc ${VnDate.hm(offline.lastSync!)}',
                  onRetry: ref.read(lecturerOfflineViewModelProvider.notifier).retry,
                ),
              ),
        body: switch (s) {
          Loading() || Empty() => const Column(children: [SkeletonList(count: 1, height: 120), SkeletonList(count: 4)]),
          Failure(:final message) => ErrorState(message: message, onRetry: vm.retry),
          Ready(:final data) => _Body(data: data),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});
  final OverviewData data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final c in d.inReview) ...[
        ClassReviewCard(schoolClass: c, onResubmit: () => context.push('/import')),
        const SizedBox(height: AppSpace.s12),
      ],
      if (!d.hasClasses)
        EmptyState(
          icon: LucideIcons.calendar,
          message: 'Chưa có lịch',
          detail: 'Hãy nhập danh sách lớp',
          actionLabel: 'Nhập',
          actionIcon: LucideIcons.fileUp,
          onAction: () => context.push('/import'),
        )
      else ...[
        _Now(slot: d.card, phase: d.cardPhase, today: d.today),
        const SizedBox(height: AppSpace.s16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: _Todo(data: d)),
          const SizedBox(width: AppSpace.s16),
          Expanded(flex: 4, child: _Agenda(slots: d.weekAgenda, today: d.today)),
        ]),
      ],
    ]);
  }
}

/// Lead area: the slot happening now (or the next one) with its main action.
class _Now extends StatelessWidget {
  const _Now({required this.slot, required this.phase, required this.today});
  final Slot? slot;
  final SlotPhase? phase;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final sl = slot;
    if (sl == null) {
      return DeskCard(
        padding: const EdgeInsets.all(AppSpace.s20),
        child: Row(children: [
          Icon(LucideIcons.calendarCheck, size: AppSize.icon20, color: c.onSurfaceVariant),
          const SizedBox(width: AppSpace.s12),
          Text('Không còn slot nào sắp tới', style: context.text.body),
        ]),
      );
    }
    final (String tag, Color dot) = switch (phase) {
      SlotPhase.live => ('Đang diễn ra · còn ${VnDate.countdown(sl.end.difference(DateTime.now()))}', st.danger),
      SlotPhase.unclosed => ('Đã hết giờ, chưa chốt', st.warning),
      SlotPhase.closed => ('Đã chốt', st.success),
      _ => (VnDate.sameDay(sl.start, today) ? 'Tiếp theo hôm nay' : 'Slot kế tiếp · ${VnDate.dayLabel(sl.start)}', c.primary),
    };
    final live = phase == SlotPhase.live;
    void open() => context.push('/session/${sl.id}');
    final actionable = phase == SlotPhase.live || phase == SlotPhase.unclosed;
    final card = DeskCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s24, vertical: AppSpace.s20),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(tag, style: context.text.caption.copyWith(color: live ? st.danger : st.fgStrong, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: AppSpace.s4),
            Text(sl.classLabel, style: context.text.display),
            const SizedBox(height: 2),
            Text('Slot ${sl.slotNo} · ${VnDate.range(sl.start, sl.end)} · Phòng ${sl.room}', style: context.text.bodySm),
          ]),
        ),
        if (live && sl.studentCount > 0) ...[
          SizedBox(
            width: 240,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Text('Đã có mặt', style: context.text.bodySm),
                const Spacer(),
                Text('${sl.presentCount} / ${sl.studentCount}', style: context.text.label.copyWith(color: st.fgStrong, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: sl.presentCount / sl.studentCount,
                  minHeight: 6,
                  backgroundColor: c.surfaceContainerHighest,
                  color: st.fill,
                ),
              ),
            ]),
          ),
          const SizedBox(width: AppSpace.s24),
        ],
        if (phase == SlotPhase.live)
          _ActionWithKey(label: 'Điểm danh', icon: LucideIcons.qrCode, keys: 'Ctrl D', onPressed: open)
        else if (phase == SlotPhase.unclosed)
          _ActionWithKey(label: 'Chốt ngay', icon: LucideIcons.check, keys: 'Ctrl D', onPressed: open)
        else
          AppButton(label: 'Xem lịch', style: AppButtonStyle.outline, size: AppButtonSize.medium, expand: false, onPressed: () => context.go('/schedule')),
      ]),
    );
    if (!actionable) return card;
    // The whole card opens the session, like the phone card ("Đang diễn ra: PRM393 · SE1801 ...").
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: '${phase == SlotPhase.live ? 'Đang diễn ra' : 'Chưa chốt'}: ${sl.classLabel}, ${VnDate.range(sl.start, sl.end)}, phòng ${sl.room}',
        onTap: open,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: open, child: card),
      ),
    );
  }
}

class _ActionWithKey extends StatelessWidget {
  const _ActionWithKey({required this.label, required this.icon, required this.keys, required this.onPressed});
  final String label;
  final IconData icon;
  final String keys;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        AppButton(label: label, icon: icon, size: AppButtonSize.medium, expand: false, onPressed: onPressed),
        const SizedBox(width: AppSpace.s8),
        Kbd(keys),
      ]);
}

class _Todo extends StatelessWidget {
  const _Todo({required this.data});
  final OverviewData data;

  @override
  Widget build(BuildContext context) {
    final d = data;
    final st = context.status;
    final c = context.colors;
    String names(List<StudentAbsence> xs) =>
        xs.take(3).map((a) => '${a.student.name} ${a.absent}/${a.limit}').join(' · ') + (xs.length > 3 ? ' …' : '');
    final r = d.latestRequest;
    final items = <Widget>[
      if (d.unclosed.isNotEmpty)
        DeskListItem(
          icon: LucideIcons.calendarX,
          iconColor: st.warning,
          iconBackground: st.warningSoft,
          title: '${d.unclosed.length} slot chưa chốt',
          subtitle: d.unclosed.take(3).map((s) => '${s.classLabel} ${VnDate.dm(s.start)}').join(' · '),
          trailing: _Small(label: 'Chốt', onPressed: () => context.push(d.unclosed.length == 1 ? '/session/${d.unclosed.single.id}' : '/unclosed')),
          onTap: () => context.push(d.unclosed.length == 1 ? '/session/${d.unclosed.single.id}' : '/unclosed'),
        ),
      if (d.pendingCount > 0)
        DeskListItem(
          icon: LucideIcons.messageSquareWarning,
          iconColor: c.primary,
          iconBackground: c.primaryContainer,
          title: '${d.pendingCount} yêu cầu sửa điểm danh',
          subtitle: r == null ? null : 'Mới nhất: ${r.studentName}, ${r.subject} · ${VnDate.dm(r.slotStart)}',
          trailing: _Small(label: 'Xem', onPressed: () => context.go('/requests')),
          onTap: () => context.go('/requests'),
        ),
      if (d.overStudents.isNotEmpty)
        DeskListItem(
          icon: LucideIcons.triangleAlert,
          iconColor: st.danger,
          iconBackground: st.dangerSoft,
          title: '${d.overStudents.length} sinh viên đã quá ngưỡng vắng',
          subtitle: names(d.overStudents),
          trailing: _Small(label: 'Xem', onPressed: () => context.push('/attention')),
          onTap: () => context.push('/attention'),
        ),
      if (d.nearStudents.isNotEmpty)
        DeskListItem(
          icon: LucideIcons.userRoundCheck,
          title: '${d.nearStudents.length} sinh viên sắp chạm ngưỡng',
          subtitle: names(d.nearStudents),
          trailing: _Small(label: 'Nhắc', onPressed: () => context.push('/attention')),
          onTap: () => context.push('/attention'),
        ),
    ];
    return DeskCard(
      title: 'Việc cần xử lý',
      count: items.length,
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.s16),
              child: EmptyState(message: 'Không có việc nào', icon: LucideIcons.circleCheck, boxed: false),
            )
          : Column(children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: AppSize.border, thickness: AppSize.border, color: c.outlineVariant.withValues(alpha: 0.6)),
                items[i],
              ],
            ]),
    );
  }
}

class _Small extends StatelessWidget {
  const _Small({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      AppButton(label: label, style: AppButtonStyle.outline, size: AppButtonSize.small, expand: false, onPressed: onPressed);
}

/// The next 7 days, grouped by day.
class _Agenda extends StatelessWidget {
  const _Agenda({required this.slots, required this.today});
  final List<Slot> slots;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final now = DateTime.now();
    final byDay = <DateTime, List<Slot>>{};
    for (final s in slots) {
      byDay.putIfAbsent(VnDate.dateOnly(s.start), () => []).add(s);
    }
    return DeskCard(
      title: '7 ngày tới',
      trailing: [AppButton(label: 'Mở lịch', style: AppButtonStyle.ghost, size: AppButtonSize.small, expand: false, trailingArrow: true, onPressed: () => context.go('/schedule'))],
      child: byDay.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.s16),
              child: EmptyState(message: 'Không có slot nào', icon: LucideIcons.calendar, boxed: false),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final e in byDay.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.s16, AppSpace.s12, AppSpace.s16, AppSpace.s4),
                  child: Text(VnDate.sameDay(e.key, today) ? 'Hôm nay · ${VnDate.dayLabel(e.key)}' : VnDate.dayLabel(e.key), style: context.text.caption),
                ),
                for (final s in e.value)
                  DeskListItem(
                    dense: true,
                    leading: SizedBox(width: 44, child: Text(VnDate.hm(s.start), style: context.text.label.copyWith(color: st.fgStrong, fontWeight: FontWeight.w600))),
                    title: s.classLabel,
                    subtitle: 'Slot ${s.slotNo} · ${s.room}',
                    trailing: switch (s.phaseAt(now)) {
                      SlotPhase.live => Text('Đang diễn ra', style: context.text.caption.copyWith(color: st.danger, fontWeight: FontWeight.w600)),
                      SlotPhase.unclosed => Text('Chưa chốt', style: context.text.caption.copyWith(color: st.warning, fontWeight: FontWeight.w600)),
                      SlotPhase.closed => Text('${s.presentCount}/${s.studentCount}', style: context.text.caption),
                      SlotPhase.upcoming => null,
                    },
                    onTap: s.phaseAt(now) == SlotPhase.upcoming ? null : () => context.push('/session/${s.id}'),
                  ),
              ],
              const SizedBox(height: AppSpace.s8),
            ]),
    );
  }
}
