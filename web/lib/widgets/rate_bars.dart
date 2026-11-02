import 'package:flutter/material.dart';
import 'package:quick_attend_core/services/dashboard_repository.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/theme/tokens.dart';

import 'admin_shell.dart';

/// Biểu đồ cột ngang: tỉ lệ có mặt theo môn, nhãn số ghi ngay trên từng hàng.
/// Dưới [warnBelow] đổi màu hổ phách và có chữ “Thấp” để không chỉ dựa vào màu.
class RateBars extends StatelessWidget {
  const RateBars({super.key, required this.rows, this.warnBelow = 0.8});

  final List<SubjectRate> rows;
  final double warnBelow;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
            child: Semantics(
              label: '${r.subject} có mặt ${(r.rate * 100).round()} phần trăm',
              excludeSemantics: true,
              child: Row(children: [
                SizedBox(width: AdminSize.rateValue, child: Text(r.subject, style: context.text.label)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: r.rate,
                      minHeight: AppSpace.s12,
                      backgroundColor: context.colors.surfaceContainerHighest,
                      color: r.rate < warnBelow ? context.status.warning : context.colors.primary,
                    ),
                  ),
                ),
                SizedBox(
                  width: AdminSize.rateValue,
                  child: Text(
                    '${(r.rate * 100).round()}%${r.rate < warnBelow ? ' · Thấp' : ''}',
                    textAlign: TextAlign.right,
                    style: context.text.label.copyWith(color: r.rate < warnBelow ? context.status.warning : context.status.fgStrong),
                  ),
                ),
              ]),
            ),
          ),
      ]);
}
