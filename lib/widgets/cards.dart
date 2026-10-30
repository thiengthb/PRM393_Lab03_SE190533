import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../utils/calendar.dart';
import 'app_button.dart';
import 'status.dart';

enum CardTone { normal, warning, live }

/// Thẻ nổi khối: viền 2 `edge` + gờ đáy 2, bo 8 (DESIGN.md mục 5).
class QaCard extends StatelessWidget {
  const QaCard({
    super.key,
    required this.child,
    this.onTap,
    this.tone = CardTone.normal,
    this.padding = const EdgeInsets.all(AppSpace.s12),
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final CardTone tone;
  final EdgeInsets padding;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final (Color bg, Color edge) = switch (tone) {
      CardTone.normal => (c.surface, c.outlineVariant),
      CardTone.warning => (c.surface, st.warning),
      CardTone.live => (c.primary, st.primaryEdge),
    };
    final radius = BorderRadius.circular(AppRadius.md);
    final card = Padding(
      padding: const EdgeInsets.only(bottom: AppSize.ledge),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: edge, width: AppSize.border),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, AppSize.ledge))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
    if (semanticsLabel == null) return card;
    return Semantics(label: semanticsLabel, button: onTap != null, container: true, child: card);
  }
}

/// Ô số ở Tổng quan và Chi tiết lớp: số lớn + nhãn.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.onTap, this.semanticsId});

  /// null → “—” (kỳ chưa có lớp, slot chưa chốt).
  final String? value;
  final String label;
  final VoidCallback? onTap;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    return QaCard(
      onTap: onTap,
      semanticsLabel: '${value ?? 'chưa có'} $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatioText.parse(value ?? '—', style: context.text.titleLg),
          const SizedBox(height: AppSpace.s4),
          Text(label, style: context.text.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Hành động trên thẻ slot.
enum SlotAction { none, attend, close, edit }

/// Slot card (Figma 4:165): upcoming, live (nền cam, nút trắng), unclosed (tam giác hổ phách), closed.
class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.slot,
    required this.phase,
    this.onTap,
    this.onAction,
    this.isNextUpcoming = false,
  });

  final Slot slot;
  final SlotPhase phase;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  /// Đồng hồ xám chỉ cho slot sắp tới gần nhất (luật Final UI).
  final bool isNextUpcoming;

  @override
  Widget build(BuildContext context) {
    final live = phase == SlotPhase.live;
    final fg = live ? context.colors.onPrimary : null;
    final action = switch (phase) {
      SlotPhase.live => SlotAction.attend,
      SlotPhase.unclosed => SlotAction.close,
      _ => SlotAction.none,
    };
    final badge = switch (phase) {
      SlotPhase.closed => const StatusBadge(StatusBadgeKind.closed),
      SlotPhase.unclosed => const StatusBadge(StatusBadgeKind.unclosed),
      SlotPhase.upcoming when isNextUpcoming => const StatusBadge(StatusBadgeKind.upcoming),
      _ => null,
    };
    final stateWord = switch (phase) {
      SlotPhase.closed => 'đã chốt',
      SlotPhase.unclosed => 'chưa chốt',
      SlotPhase.live => 'đang diễn ra',
      SlotPhase.upcoming => 'sắp tới',
    };
    return QaCard(
      tone: live
          ? CardTone.live
          : phase == SlotPhase.unclosed
              ? CardTone.warning
              : CardTone.normal,
      onTap: onTap,
      semanticsLabel: 'Slot ${slot.slotNo} ${slot.classLabel} ${VnDate.range(slot.start, slot.end)} $stateWord',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  VnDate.range(slot.start, slot.end),
                  style: context.text.bodySm.copyWith(color: fg ?? context.colors.onSurfaceVariant),
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Text(slot.classLabel, style: context.text.title.copyWith(color: fg)),
          const SizedBox(height: AppSpace.s4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: fg ?? context.colors.onSurfaceVariant),
              const SizedBox(width: AppSpace.s4),
              Text(slot.room, style: context.text.bodySm.copyWith(color: fg ?? context.colors.onSurfaceVariant)),
              const Spacer(),
              if (action != SlotAction.none && onAction != null)
                AppButton(
                  label: action == SlotAction.attend ? 'Điểm danh' : 'Chốt ngay',
                  icon: action == SlotAction.attend ? Icons.qr_code_2 : Icons.check,
                  style: action == SlotAction.attend ? AppButtonStyle.onPrimary : AppButtonStyle.primary,
                  size: AppButtonSize.medium,
                  expand: false,
                  onPressed: onAction,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
