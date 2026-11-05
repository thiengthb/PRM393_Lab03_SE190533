import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Logo Hereby: người giơ tay trên ô bo góc có gờ dưới (Figma App icon v2 `262:2800`).
/// Vẽ đúng hình học của file SVG xuất từ Figma (`design/icon/hereby-app-icon.svg`), màu lấy theo bảng màu.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _HerebyMarkPainter(
            face: context.status.brand,
            ledge: context.status.primaryEdge,
            glyph: context.colors.onPrimary,
          ),
        ),
      );
}

class _HerebyMarkPainter extends CustomPainter {
  const _HerebyMarkPainter({required this.face, required this.ledge, required this.glyph});

  final Color face;
  final Color ledge;
  final Color glyph;

  @override
  void paint(Canvas canvas, Size size) {
    // Toạ độ gốc trên khung 64 × 64 của Figma.
    canvas.scale(size.width / 64, size.height / 64);
    const r = Radius.circular(14.6667);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 64, 64), r), Paint()..color = ledge);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 64, 61.3333), r), Paint()..color = face);

    final fill = Paint()..color = glyph;
    canvas.drawCircle(const Offset(26.6668, 19.9998), 7.3333, fill);
    // Thân: nửa trên bo tròn bán kính 12, đáy phẳng ở y = 52.
    final body = Path()
      ..moveTo(14.6665, 52)
      ..lineTo(14.6665, 41.3335)
      ..arcToPoint(const Offset(38.6665, 41.3335), radius: const Radius.circular(12))
      ..lineTo(38.6665, 52)
      ..close();
    canvas.drawPath(body, fill);
    // Tay giơ lên.
    canvas.drawLine(
      const Offset(36, 37.3335),
      const Offset(46.6667, 13.3335),
      Paint()
        ..color = glyph
        ..strokeWidth = 6.66667
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HerebyMarkPainter old) => old.face != face || old.ledge != ledge || old.glyph != glyph;
}

/// Hàng logo + “Hereby” ở đầu các màn đăng nhập và web sinh viên.
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const BrandMark(),
          const SizedBox(width: AppSpace.s12),
          Expanded(child: Text('Hereby', style: context.text.title, semanticsLabel: 'Hereby')),
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
