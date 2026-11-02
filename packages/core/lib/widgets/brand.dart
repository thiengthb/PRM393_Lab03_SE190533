import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Logo Quick Attend: ô cam FPT bo 8, chữ Q trắng.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'Q',
            style: context.text.titleLg.copyWith(color: context.colors.onPrimary, fontSize: size * 0.55, height: 1),
          ),
        ),
      );
}

/// Hàng logo + “Quick Attend” ở đầu các màn đăng nhập và web sinh viên.
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const BrandMark(),
          const SizedBox(width: AppSpace.s12),
          Expanded(child: Text('Quick Attend', style: context.text.title, semanticsLabel: 'Quick Attend')),
          ?trailing,
        ],
      );
}

/// Dải “hoặc” giữa đăng nhập email và Google.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
        child: Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
              child: Text('hoặc', style: context.text.bodySm),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      );
}
