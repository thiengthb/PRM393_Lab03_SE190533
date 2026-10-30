import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'cards.dart';
import 'status.dart';

/// Hàng sinh viên trong phiên điểm danh: avatar, tên, MSSV, công tắc có mặt.
class StudentRow extends StatelessWidget {
  const StudentRow({
    super.key,
    required this.name,
    required this.code,
    this.present,
    this.onChanged,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String code;

  /// null: không hiện công tắc.
  final bool? present;
  final ValueChanged<bool>? onChanged;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = present;
    return QaCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s8),
      child: Row(
        children: [
          InitialsAvatar(name: name),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.text.body.copyWith(color: context.status.fgStrong)),
                Text(code, style: context.text.bodySm),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (p != null)
            Semantics(
              label: 'Có mặt $name',
              toggled: p,
              child: Switch(value: p, onChanged: onChanged),
            ),
        ],
      ),
    );
  }
}

/// Attention row: near (hổ phách), over (đỏ); số “3/4”, không chip.
class AttentionRow extends StatelessWidget {
  const AttentionRow({super.key, required this.item, this.onTap, this.showClass = true});

  final StudentAbsence item;
  final VoidCallback? onTap;
  final bool showClass;

  @override
  Widget build(BuildContext context) {
    final s = item.student;
    final sub = showClass ? '${s.code} · ${item.schoolClass.code}' : s.code;
    return QaCard(
      onTap: onTap,
      semanticsLabel: '${s.name}, ${item.absent} trên ${item.limit} buổi vắng',
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s8),
      child: Row(
        children: [
          InitialsAvatar(name: s.name),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: context.text.body.copyWith(color: context.status.fgStrong)),
                Text(sub, style: context.text.bodySm),
              ],
            ),
          ),
          RatioText(
            value: '${item.absent}',
            total: '${item.limit}',
            color: absenceColor(context, item.level),
          ),
        ],
      ),
    );
  }
}

/// Date header (Figma 91:189): kỳ trái, thứ ngày phải.
class DateHeader extends StatelessWidget {
  const DateHeader({super.key, required this.left, this.right});

  final String left;
  final String? right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
        child: Row(
          children: [
            Expanded(child: Text(left, style: context.text.section)),
            if (right != null) Text(right!, style: context.text.body.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      );
}

/// Tiêu đề nhóm, có thể kèm icon và nút “Xem tất cả ›”.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.icon, this.iconColor, this.actionLabel, this.onAction});

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AppSize.touch,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSize.icon20, color: iconColor),
              const SizedBox(width: AppSpace.s8),
            ],
            Expanded(child: Text(title, style: context.text.section, semanticsLabel: title)),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(minimumSize: const Size(AppSize.touch, AppSize.touch)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel!, style: context.text.label.copyWith(color: context.colors.primary)),
                    Icon(Icons.chevron_right, size: AppSize.icon20, color: context.colors.primary),
                  ],
                ),
              ),
          ],
        ),
      );
}

/// Hàng buổi học: ngày, “Slot 1 · P.305”, phần phải (chip hoặc số).
class SessionRow extends StatelessWidget {
  const SessionRow({super.key, required this.title, required this.subtitle, this.trailing, this.onTap});

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => QaCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12, vertical: AppSpace.s12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.body.copyWith(color: context.status.fgStrong)),
                  Text(subtitle, style: context.text.bodySm),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}
