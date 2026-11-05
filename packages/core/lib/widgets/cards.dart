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

/// Thẻ như `card.tsx` của thienui: nền trắng, viền 1 --border, bo 10, không bóng, đệm 16.
/// [CardKind] chỉ còn ý nghĩa ngữ nghĩa (thẻ bấm được có hiệu ứng nhấn). Đang diễn ra: nền
/// [StatusColors.fill]. Cần chú ý: viền hổ phách.
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
    if (tone == CardTone.normal && CardList._inList(context)) {
      // Trong [CardList]: thành một hàng của thẻ chung, không viền, không bóng.
      final row = _Ink(radius: BorderRadius.zero, onTap: onTap, padding: padding, child: child);
      return semanticsLabel == null ? row : Semantics(label: semanticsLabel, button: onTap != null, container: true, child: row);
    }
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
      ),
      child: _Ink(radius: radius, onTap: onTap, padding: padding, child: child),
    );
    if (semanticsLabel == null) return card;
    return Semantics(label: semanticsLabel, button: onTap != null, container: true, child: card);
  }
}

/// Một thẻ trắng chứa nhiều hàng ngăn bằng đường kẻ (danh sách sinh viên, buổi học, cài đặt).
/// Mỗi [QaCard] tone thường bên trong tự thành hàng phẳng, nên chỗ gọi chỉ cần bọc danh sách.
class CardList extends StatelessWidget {
  const CardList({super.key, required this.children, this.dividerIndent = 0});

  final List<Widget> children;

  /// Lùi đường kẻ cho thẳng chữ (ví dụ 64 khi hàng có avatar 40).
  final double dividerIndent;

  static bool _inList(BuildContext context) => context.getInheritedWidgetOfExactType<_InCardList>() != null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.outlineVariant, width: AppSize.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _InCardList(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: AppSize.border, thickness: AppSize.border, indent: dividerIndent, color: c.outlineVariant),
              children[i],
            ],
          ]),
        ),
      ),
    );
  }
}

class _InCardList extends InheritedWidget {
  const _InCardList({required super.child});

  @override
  bool updateShouldNotify(_InCardList oldWidget) => false;
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

/// Ô số kiểu thẻ số liệu shadcn: nhãn nhỏ màu phụ ở trên, icon 16 góc phải, số to 24 đậm 600 ở dưới.
/// Bấm được: nhãn màu primary kèm mũi tên.
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
    final radius = BorderRadius.circular(AppRadius.lg);
    final content = Padding(
      padding: const EdgeInsets.all(AppSpace.s16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              label,
              style: context.text.bodySm.copyWith(color: tappable ? c.primary : null, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (tappable)
            Icon(Icons.arrow_forward, size: 16, color: c.primary)
          else if (icon != null)
            Icon(icon, size: 16, color: c.onSurfaceVariant),
        ]),
        const SizedBox(height: AppSpace.s8),
        RatioText.parse(value ?? '—', style: context.text.titleLg.copyWith(fontSize: 24, height: 1.2, color: color ?? st.fgStrong)),
      ]),
    );
    return Semantics(
      label: '${value ?? 'chưa có'} $label',
      button: tappable,
      container: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: radius,
          border: Border.all(color: c.outlineVariant, width: AppSize.border),
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
