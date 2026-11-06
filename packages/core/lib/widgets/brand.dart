import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Logo Hereby: người giơ tay trên ô bo góc phẳng (hình học từ Figma App icon v2 `262:2800`).
/// Vẽ đúng hình học của file SVG xuất từ Figma (`design/icon/hereby-app-icon.svg`), màu lấy theo bảng màu.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.onDark = false});

  final double size;

  /// Trên nền màu thương hiệu: ô trắng, khung và chấm màu primary.
  final bool onDark;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: onDark
          ? _HerebyMarkPainter(face: Colors.white, glyph: context.colors.primary)
          : _HerebyMarkPainter(face: context.status.brand, glyph: Colors.white),
    ),
  );
}

/// Logo 06/11/2026: chấm tròn nằm giữa khung ngắm bốn góc (“bạn đang ở đây”), trên ô vuông bo
/// màu phẳng. Cùng hình với design/icon/hereby-app-icon.svg (khung 64 × 64).
class _HerebyMarkPainter extends CustomPainter {
  const _HerebyMarkPainter({required this.face, required this.glyph});

  final Color face;
  final Color glyph;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 64, 64), const Radius.circular(15)),
      Paint()..color = face,
    );
    final stroke = Paint()
      ..color = glyph
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const r = Radius.circular(4);
    // Bốn góc khung ngắm, mỗi góc dài 10, bo 4.
    canvas
      ..drawPath(
        Path()
          ..moveTo(15, 25)
          ..lineTo(15, 19)
          ..arcToPoint(const Offset(19, 15), radius: r)
          ..lineTo(25, 15),
        stroke,
      )
      ..drawPath(
        Path()
          ..moveTo(39, 15)
          ..lineTo(45, 15)
          ..arcToPoint(const Offset(49, 19), radius: r)
          ..lineTo(49, 25),
        stroke,
      )
      ..drawPath(
        Path()
          ..moveTo(49, 39)
          ..lineTo(49, 45)
          ..arcToPoint(const Offset(45, 49), radius: r)
          ..lineTo(39, 49),
        stroke,
      )
      ..drawPath(
        Path()
          ..moveTo(25, 49)
          ..lineTo(19, 49)
          ..arcToPoint(const Offset(15, 45), radius: r)
          ..lineTo(15, 39),
        stroke,
      )
      // Chấm giữa.
      ..drawCircle(const Offset(32, 32), 8, Paint()..color = glyph);
  }

  @override
  bool shouldRepaint(_HerebyMarkPainter old) => old.face != face || old.glyph != glyph;
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
      Expanded(
        child: Text('Hereby', style: context.text.title, semanticsLabel: 'Hereby'),
      ),
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
