import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Công tắc: rãnh viên thuốc 44x26, bật màu fill của bảng màu,
/// tắt xám fgDisabled; nút tròn trắng 20, cách mép 3, đổ bóng nhẹ.
/// Vùng bấm 48 theo đề, hình vẫn 44x26.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  static const _w = 44.0;
  static const _h = 26.0;
  static const _knob = 20.0;
  static const _inset = 3.0;
  static const _duration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final enabled = onChanged != null;
    final track = AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOut,
      width: _w,
      height: _h,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: value ? st.fill : st.fgDisabled,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: AnimatedAlign(
        duration: _duration,
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: _knob,
          height: _knob,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [AppShadow.hairline],
          ),
        ),
      ),
    );
    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: enabled,
      onTap: enabled ? () => onChanged!(!value) : null,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onChanged!(!value) : null,
          child: SizedBox(
            width: AppSize.touch,
            height: AppSize.touch,
            child: Center(child: Opacity(opacity: enabled ? 1 : 0.5, child: track)),
          ),
        ),
      ),
    );
  }
}

/// Icon "Đổi mã" vẽ theo Figma (`259:2938`, hai mũi tên quay vòng, nét 1.33 trên khung 16).
/// Material không có hình này nên vẽ tay để giống thiết kế.
class RotateCodeIcon extends StatelessWidget {
  const RotateCodeIcon({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _RotatePainter(color ?? context.colors.onSurfaceVariant),
        ),
      );
}

class _RotatePainter extends CustomPainter {
  _RotatePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 16;
    canvas.scale(s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33333
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Đường dẫn chép từ SVG xuất ra của Figma.
    canvas.drawPath(
      Path()
        ..moveTo(2, 8)
        ..cubicTo(2, 6.4087, 2.63214, 4.88258, 3.75736, 3.75736)
        ..cubicTo(4.88258, 2.63214, 6.4087, 2, 8, 2)
        ..cubicTo(9.67737, 2.00631, 11.2874, 2.66082, 12.4933, 3.82667)
        ..lineTo(14, 5.33333),
      p,
    );
    canvas.drawPath(Path()..moveTo(14, 2)..lineTo(14, 5.33333)..lineTo(10.6667, 5.33333), p);
    canvas.drawPath(
      Path()
        ..moveTo(14, 8)
        ..cubicTo(14, 9.5913, 13.3679, 11.1174, 12.2426, 12.2426)
        ..cubicTo(11.1174, 13.3679, 9.5913, 14, 8, 14)
        ..cubicTo(6.32263, 13.9937, 4.71265, 13.3392, 3.50667, 12.1733)
        ..lineTo(2, 10.6667),
      p,
    );
    canvas.drawPath(Path()..moveTo(5.33333, 10.6665)..lineTo(2, 10.6665)..lineTo(2, 13.9998), p);
  }

  @override
  bool shouldRepaint(_RotatePainter old) => old.color != color;
}
