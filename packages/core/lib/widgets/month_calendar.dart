import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../utils/calendar.dart';

/// Lịch tháng có chấm ở GV-001: ô 48 × 46, số trong ô 32, hôm nay là ô primary.
/// Bấm một ngày thì [onSelect] (Tổng quan chuyển sang tab Điểm danh, đúng ngày đó).
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.dots,
    required this.slotCount,
    required this.onSelect,
    required this.onShift,
  });

  /// Ngày 1 của tháng đang xem.
  final DateTime month;
  final DateTime today;

  /// Ngày trong tháng → các chấm, theo giờ bắt đầu.
  final Map<int, List<DayDot>> dots;
  final int slotCount;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = month.weekday - 1;
    final rows = ((lead + daysInMonth) / 7).ceil();
    return Column(children: [
      Row(children: [
        _Arrow(icon: Icons.chevron_left, tooltip: 'Tháng trước', onTap: () => onShift(-1)),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Tháng ${month.month} · $slotCount slot',
              textAlign: TextAlign.center,
              style: context.text.title.copyWith(color: context.status.fgStrong),
            ),
          ),
        ),
        _Arrow(icon: Icons.chevron_right, tooltip: 'Tháng sau', onTap: () => onShift(1)),
      ]),
      const SizedBox(height: AppSpace.s8),
      Row(children: [
        for (final w in VnDate.shortWeekdays)
          Expanded(
            child: SizedBox(height: 22, child: Center(child: Text(w, style: context.text.caption.copyWith(fontWeight: FontWeight.w500)))),
          ),
      ]),
      for (var r = 0; r < rows; r++)
        Row(children: [
          for (var c = 0; c < 7; c++) Expanded(child: _cell(context, r * 7 + c - lead + 1, daysInMonth)),
        ]),
    ]);
  }

  Widget _cell(BuildContext context, int day, int max) {
    if (day < 1 || day > max) return const SizedBox(height: 46);
    final date = DateTime(month.year, month.month, day);
    final isToday = VnDate.sameDay(date, today);
    final past = date.isBefore(VnDate.dateOnly(today));
    final ds = dots[day] ?? const [];
    final st = context.status;
    Color dotColor(DayDot d) => switch (d) {
          DayDot.closed => st.success,
          DayDot.unclosed => st.warning,
          DayDot.live => context.colors.primary,
          DayDot.upcoming => st.fgDisabled,
        };
    final unclosed = ds.where((d) => d == DayDot.unclosed).length;
    return Semantics(
      label: '${VnDate.dayLabel(date)}${isToday ? ', hôm nay' : ''}'
          '${ds.isEmpty ? '' : ', ${ds.length} slot'}${unclosed > 0 ? ', $unclosed chưa chốt' : ''}',
      button: true,
      selected: isToday,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => onSelect(date),
        child: SizedBox(
          height: 46,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? context.colors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$day',
                style: context.text.label.copyWith(
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday
                      ? context.colors.onPrimary
                      : past
                          ? context.colors.onSurfaceVariant
                          : st.fgStrong,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < ds.length && i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor(ds[i]))),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: AppSize.icon24, color: context.status.fgStrong),
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints.tightFor(width: AppSize.touch, height: AppSize.touch),
      );
}
