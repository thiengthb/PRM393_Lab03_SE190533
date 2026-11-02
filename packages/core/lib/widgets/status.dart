import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Status chip (Figma 3:74): Present / Absent; bo 8, đệm 4/8, không icon, không viền.
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8, vertical: AppSpace.s4),
        decoration: BoxDecoration(
          color: present ? st.successSoft : st.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(label, style: context.text.label.copyWith(color: present ? st.success : st.danger)),
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
        child: Icon(Icons.warning_rounded, size: AppSize.badge + 2, color: st.warning),
      );
    }
    final (Color bg, IconData icon, double size) = switch (kind) {
      StatusBadgeKind.closed => (st.success, Icons.check_rounded, 12.0),
      StatusBadgeKind.upcoming => (context.colors.onSurfaceVariant, Icons.schedule_rounded, 14.0),
      _ => (st.danger, Icons.close_rounded, 12.0),
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
        decoration: BoxDecoration(color: context.colors.primaryContainer, shape: BoxShape.circle),
        child: Text(
          initials(name),
          style: context.text.label.copyWith(color: context.colors.onPrimaryContainer),
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
        child: Icon(icon, size: AppSize.icon24, color: color ?? context.colors.onSurfaceVariant),
      );
}
