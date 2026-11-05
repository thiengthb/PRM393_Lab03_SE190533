import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../utils/calendar.dart';
import 'app_button.dart';
import 'status.dart';

enum CardTone { normal, warning, live }

/// Thẻ bấm được thì nổi (viền + bóng), chỉ để xem thì phẳng (viền, không bóng).
enum CardKind { raised, sunken }

/// Thẻ trắng bo 12 trên nền xám lạnh (bản thiết kế lại 11/2026). Nổi: viền 1 + bóng [AppShadow.card].
/// Phẳng: chỉ viền 1. Đang diễn ra: nền [StatusColors.fill]. Cần chú ý: viền hổ phách.
/// Không truyền [kind] thì thẻ có [onTap] hoặc [tone] khác normal là thẻ nổi, còn lại là thẻ phẳng.
/// Thẻ không bấm được nhưng chứa nút hoặc công tắc thì truyền `kind: CardKind.raised`.
class QaCard extends StatelessWidget {
  const QaCard({
    super.key,
    required this.child,
    this.onTap,
    this.tone = CardTone.normal,
    this.kind,
    this.padding = const EdgeInsets.all(AppSpace.s16),
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final CardTone tone;
  final CardKind? kind;
  final EdgeInsets padding;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final raised = (kind ?? (onTap != null || tone != CardTone.normal ? CardKind.raised : CardKind.sunken)) == CardKind.raised;
    final radius = BorderRadius.circular(AppRadius.lg);
    final (Color bg, Color? edge) = switch (tone) {
      CardTone.normal => (c.surface, c.outlineVariant),
      CardTone.warning => (c.surface, st.warningSoftEdge),
      CardTone.live => (st.fill, null),
    };
    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: edge == null ? null : Border.all(color: edge, width: AppSize.border),
        boxShadow: raised ? AppShadow.card : null,
      ),
      child: _Ink(radius: radius, onTap: onTap, padding: padding, child: child),
    );
    if (semanticsLabel == null) return card;
    return Semantics(label: semanticsLabel, button: onTap != null, container: true, child: card);
  }
}

class _Ink extends StatelessWidget {
  const _Ink({required this.radius, required this.onTap, required this.padding, required this.child});
  final BorderRadius radius;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// Ô số: thẻ trắng viền 1, ô icon primary-soft. Bấm được: nền primary-soft, viền primary-soft-edge,
/// ô icon trắng, chữ on-primary-soft, mũi tên.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.icon, this.color, this.onTap, this.semanticsId});

  /// null → “—” (kỳ chưa có lớp, slot chưa chốt).
  final String? value;
  final String label;
  final IconData? icon;

  /// Màu số (ví dụ đỏ cho số vắng ở GV-102 .S); mặc định fg-strong.
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final tappable = onTap != null;
    final fg = tappable ? c.onPrimaryContainer : (color ?? st.fgStrong);
    final radius = BorderRadius.circular(AppRadius.lg);
    final content = Padding(
      padding: const EdgeInsets.all(AppSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tappable ? c.surface : c.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 18, color: c.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpace.s12),
            ],
            Expanded(child: RatioText.parse(value ?? '—', style: context.text.titleLg.copyWith(color: fg))),
            if (tappable) Icon(Icons.chevron_right, size: 16, color: fg),
          ]),
          const SizedBox(height: AppSpace.s4),
          Text(
            label,
            style: context.text.bodySm.copyWith(color: tappable ? c.onPrimaryContainer : null),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    return Semantics(
      label: '${value ?? 'chưa có'} $label',
      button: tappable,
      container: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tappable ? c.primaryContainer : c.surface,
          borderRadius: radius,
          border: Border.all(color: tappable ? st.primarySoftEdge : c.outlineVariant, width: AppSize.border),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(borderRadius: radius, onTap: onTap, child: content),
        ),
      ),
    );
  }
}

/// Hành động trên thẻ slot.
enum SlotAction { none, attend, close, edit }

/// Thẻ slot: upcoming, live (nền fill, nút trắng), unclosed (viền và nhãn hổ phách), closed.
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
    final fg = live ? context.status.onFill : null;
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
      kind: CardKind.raised,
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
