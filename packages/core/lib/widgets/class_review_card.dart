import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'cards.dart';
import 'status.dart';

/// Thẻ một lớp đang chờ duyệt hoặc bị từ chối (app giảng viên, GV-001 và GV-003).
class ClassReviewCard extends StatelessWidget {
  const ClassReviewCard({super.key, required this.schoolClass, this.onResubmit});

  final SchoolClass schoolClass;
  final VoidCallback? onResubmit;

  @override
  Widget build(BuildContext context) {
    final rejected = schoolClass.status == ClassStatus.rejected;
    final word = rejected ? 'Bị từ chối' : 'Chờ giáo vụ duyệt';
    return QaCard(
      tone: rejected ? CardTone.warning : CardTone.normal,
      semanticsLabel: '${schoolClass.label}, $word',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconTile(
            icon: rejected ? Icons.error_outline_rounded : Icons.hourglass_empty_rounded,
            size: 40,
            background: rejected ? context.status.warningSoft : null,
            color: rejected ? context.status.warning : null,
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(schoolClass.label, style: context.text.bodyStrong.copyWith(color: context.status.fgStrong)),
              Text(word, style: context.text.bodySm),
            ]),
          ),
        ]),
        if (rejected) ...[
          if ((schoolClass.rejectReason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpace.s8),
            Text(schoolClass.rejectReason!, style: context.text.body),
          ],
          if (onResubmit != null) ...[
            const SizedBox(height: AppSpace.s12),
            AppButton(label: 'Nhập lại', icon: Icons.upload_file_outlined, size: AppButtonSize.medium, onPressed: onResubmit),
          ],
        ],
      ]),
    );
  }
}
