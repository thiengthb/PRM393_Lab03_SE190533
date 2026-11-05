import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Logo Hereby: người giơ tay trên ô bo góc phẳng (hình học từ Figma App icon v2 `262:2800`).
/// Vẽ đúng hình học của file SVG xuất từ Figma (`design/icon/hereby-app-icon.svg`), màu lấy theo bảng màu.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.onDark = false});

  final double size;

  /// Trên nền màu thương hiệu: ô trắng, chữ H màu primary.
  final bool onDark;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: onDark
          ? _HerebyMarkPainter(face: Colors.white, glyph: context.colors.primary)
          : _HerebyMarkPainter(face: context.status.brand, glyph: context.colors.onPrimary),
    ),
  );
}

/// Logo 06/11/2026: chữ H có thanh ngang là dấu tích, trên ô vuông bo màu phẳng.
/// Cùng hình với design/icon/hereby-app-icon.svg (khung 64 × 64).
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
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Hai chân chữ H.
    canvas.drawLine(const Offset(19, 16), const Offset(19, 48), stroke);
    canvas.drawLine(const Offset(45, 16), const Offset(45, 48), stroke);
    // Thanh ngang là dấu tích.
    canvas.drawPath(
      Path()
        ..moveTo(19, 34)
        ..lineTo(27, 41)
        ..lineTo(45, 24),
      stroke,
    );
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
