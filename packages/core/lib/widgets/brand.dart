import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Tên thương hiệu (thien chọn 06/11/2026). Firebase project, khoá cấu hình và tên gói giữ nguyên.
abstract final class AppBrand {
  static const name = 'Attendo';
  static const tagline = 'Điểm danh trong một lần quét.';
}

/// Biểu tượng Attendo: vòng tròn có chấm giữa (chữ o cuối của logo chữ, nghĩa là “bạn ở đây”)
/// trên ô bo góc phẳng. Cùng hình với design/brand/attendo-app-icon.svg (khung 64 × 64). Chỉ
/// dùng ở chỗ hẹp (icon app, thanh bên thu gọn, màn chờ); chỗ đủ rộng dùng [BrandWordmark].
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.onDark = false});

  final double size;

  /// Trên nền màu thương hiệu: ô trắng, vòng màu primary.
  final bool onDark;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: onDark
          ? _MarkPainter(face: Colors.white, glyph: context.colors.primary)
          : _MarkPainter(face: context.status.brand, glyph: Colors.white),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.face, required this.glyph});

  final Color face;
  final Color glyph;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 64, 64), const Radius.circular(15)),
      Paint()..color = face,
    );
    _paintRing(canvas, const Offset(32, 32), 16, 8, 5.5, glyph);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.face != face || old.glyph != glyph;
}

/// Vòng có chấm giữa, dùng chung cho biểu tượng và chữ o của logo chữ.
void _paintRing(Canvas canvas, Offset c, double r, double stroke, double dot, Color color) {
  canvas
    ..drawCircle(
      c,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    )
    ..drawCircle(c, dot, Paint()..color = color);
}

/// Logo chữ “attendo”: Onest 700 chữ thường, khít chữ; chữ o cuối là vòng có chấm màu thương
/// hiệu. Bản sáng: chữ mực, vòng màu primary; bản tối: chữ sáng, vòng primary sáng.
/// [onBrand]: trên nền fill đặc thì chữ onFill, vòng trắng.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 26, this.onBrand = false, this.color});

  /// Cỡ chữ (px). Vòng o cao bằng 0,52 cỡ chữ, ngồi trên đường chân chữ.
  final double size;
  final bool onBrand;

  /// Màu chữ riêng (ví dụ trên màn chiếu). Mặc định: mực của theme.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final ink = color ?? (onBrand ? st.onFill : st.fgStrong);
    final ring = onBrand ? Colors.white : context.colors.primary;
    final o = size * 0.52;
    return Semantics(
      label: AppBrand.name,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: 'attend',
          children: [
            // Vòng o ngồi trên đường chân chữ, sát chữ d như chữ o thật.
            WidgetSpan(
              alignment: PlaceholderAlignment.aboveBaseline,
              baseline: TextBaseline.alphabetic,
              child: Padding(
                padding: EdgeInsets.only(left: size * 0.02),
                child: Transform.translate(
                  offset: Offset(0, size * 0.015),
                  child: CustomPaint(size: Size.square(o), painter: _RingPainter(ring)),
                ),
              ),
            ),
          ],
        ),
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: AppFont.family,
          package: AppFont.package,
          fontSize: size,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.045 * size,
          color: ink,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Khung 40: vòng bán kính 15,5 nét 7,5, chấm 5 (cùng hình với SVG logo chữ).
    canvas.scale(size.width / 40, size.height / 40);
    _paintRing(canvas, const Offset(20, 20), 15.5, 7.5, 5, color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}

/// Logo chữ ở đầu các màn đăng nhập, web sinh viên và thanh bên.
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const BrandWordmark(),
      const Spacer(),
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
