import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Status chip: Có mặt / Vắng; viên thuốc, đệm 4/8, không icon, không viền.
class StatusChip extends StatelessWidget {
  const StatusChip.present({super.key}) : present = true;
  const StatusChip.absent({super.key}) : present = false;

  final bool present;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final label = present ? 'Có mặt' : 'Vắng';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8, vertical: 2),
        decoration: BoxDecoration(
          color: present ? st.successSoft : st.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(label, style: context.text.caption.copyWith(color: present ? st.success : st.danger)),
      ),
    );
  }
}

enum StatusBadgeKind { closed, upcoming, unclosed, error }

/// Status badge (Figma 96:3177): tròn đặc 20, ký hiệu trắng.
/// Unclosed là tam giác “!” hổ phách như icon Chú ý.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.kind, {super.key});

  final StatusBadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final label = switch (kind) {
      StatusBadgeKind.closed => 'Đã chốt',
      StatusBadgeKind.upcoming => 'Sắp tới',
      StatusBadgeKind.unclosed => 'Chưa chốt',
      StatusBadgeKind.error => 'Lỗi',
    };
    if (kind == StatusBadgeKind.unclosed) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: Icon(LucideIcons.triangleAlert, size: AppSize.badge + 2, color: st.warning),
      );
    }
    final (Color bg, IconData icon, double size) = switch (kind) {
      StatusBadgeKind.closed => (st.success, LucideIcons.check, 12.0),
      StatusBadgeKind.upcoming => (context.colors.onSurfaceVariant, LucideIcons.clock, 14.0),
      _ => (st.danger, LucideIcons.x, 12.0),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        width: AppSize.badge,
        height: AppSize.badge,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: size, color: context.colors.onPrimary, weight: 700),
      ),
    );
  }
}

/// Số dạng “5/4”: số chính Bold, “/4” Regular (luật Final UI).
class RatioText extends StatelessWidget {
  const RatioText({super.key, required this.value, this.total, this.color, this.style});

  /// Tách “7/10” thành 7 và 10; chuỗi không có “/” hiện nguyên.
  factory RatioText.parse(String text, {Key? key, Color? color, TextStyle? style}) {
    final i = text.indexOf('/');
    if (i < 0) return RatioText(key: key, value: text, color: color, style: style);
    return RatioText(key: key, value: text.substring(0, i), total: text.substring(i + 1), color: color, style: style);
  }

  final String value;
  final String? total;
  final Color? color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? context.text.title).copyWith(color: color);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: value, style: base.copyWith(fontWeight: FontWeight.w700)),
        if (total != null) TextSpan(text: '/$total', style: base.copyWith(fontWeight: FontWeight.w400)),
      ]),
      semanticsLabel: total == null ? value : '$value trên $total',
    );
  }
}

/// Màu số vắng theo mức: hổ phách sắp chạm, đỏ quá ngưỡng.
Color absenceColor(BuildContext context, AbsenceLevel level) => switch (level) {
      AbsenceLevel.over => context.status.danger,
      AbsenceLevel.near => context.status.warning,
      AbsenceLevel.ok => context.status.fgStrong,
    };

/// Avatar chữ viết tắt trên primary-soft, không viền (luật Final UI).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = AppSize.avatar});

  final String name;
  final double size;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    // “Lê Thu Trang” → “TT”: chữ đầu của tên đệm cuối và tên.
    return (parts[parts.length - 2].characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        // Avatar shadcn: nền --muted, chữ --muted-foreground, viền mảnh.
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.outlineVariant, width: AppSize.border),
        ),
        child: Text(
          initials(name),
          style: context.text.label.copyWith(color: context.colors.onSurfaceVariant, fontSize: size < 36 ? 12 : 13),
        ),
      ),
    );
  }
}

/// Ô vuông bo 8 chứa icon (ô trống, bước GV-093, cảnh báo).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.background, this.color, this.size = 48});

  final IconData icon;
  final Color? background;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: size >= 44 ? 20 : 18, color: color ?? context.colors.onSurfaceVariant),
      );
}

/// Khối Đếm buổi vắng v2 (SV-002 `295:3703`, GV-201 `278:5269`): "3/4 buổi vắng" và
/// thanh chia đúng số buổi được vắng, đoạn đã vắng tô [color].
class AbsenceMeter extends StatelessWidget {
  const AbsenceMeter({super.key, required this.absent, required this.limit, required this.color});
  final int absent;
  final int limit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = context.text.display.copyWith(color: color);
    final parts = limit < 1 ? 1 : limit;
    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant, width: AppSize.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          label: 'Vắng $absent trên $limit buổi được vắng',
          child: ExcludeSemantics(
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('$absent/$limit', style: base),
              const SizedBox(width: AppSpace.s8),
              Text('buổi vắng', style: context.text.body),
            ]),
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        Row(children: [
          for (var i = 0; i < parts; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: i < absent ? color : context.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

/// Chip "Đã fail" cạnh tên (GV-201 .D1 `278:5335`).
class FailedChip extends StatelessWidget {
  const FailedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8, vertical: 2),
      decoration: BoxDecoration(color: st.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text('Đã fail', style: context.text.caption.copyWith(color: st.danger, fontWeight: FontWeight.w700)),
    );
  }
}
