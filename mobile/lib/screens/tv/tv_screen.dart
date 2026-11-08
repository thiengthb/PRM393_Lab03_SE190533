import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:quick_attend_core/models/models.dart';
import 'package:quick_attend_core/theme/app_theme.dart';
import 'package:quick_attend_core/utils/calendar.dart';
import '../../viewmodels/tv_viewmodel.dart';
import 'package:quick_attend_core/widgets/controls.dart';

/// TV-001 Màn chiếu (web, không đăng nhập). Bên trái QR và mã số, bên phải lớp và số đã quét.
class TvScreen extends ConsumerWidget {
  const TvScreen({super.key, required this.tvKey});
  final String tvKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(tvViewModelProvider(tvKey));
    // Màn chiếu tự co chữ theo chiều cao (unit), không nhận hệ số chữ màn rộng của WideTextScale.
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
      backgroundColor: context.colors.surface,
      body: LayoutBuilder(builder: (context, box) {
        // Thiết kế 1280×720; mọi kích thước co theo chiều cao màn.
        final landscape = box.maxWidth >= box.maxHeight;
        final unit = (landscape ? box.maxHeight / 720 : box.maxWidth / 720).clamp(0.4, 3.0).toDouble();
        final left = _Left(state: s, unit: unit);
        final right = _Panel(state: s, unit: unit);
        return landscape
            ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(flex: 760, child: left),
                Expanded(flex: 520, child: right),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(flex: 3, child: left),
                Expanded(flex: 2, child: right),
              ]);
      }),
      ),
    );
  }
}

class _Left extends StatelessWidget {
  const _Left({required this.state, required this.unit});
  final TvState state;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final fg = context.status.fgStrong;
    final title = context.text.display.copyWith(color: fg, fontSize: 36 * unit);
    return Center(
      child: switch (state) {
        TvLoading() => const CircularProgressIndicator(),
        TvIdle() => Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Chưa mở điểm danh', style: title, textAlign: TextAlign.center),
            SizedBox(height: 12 * unit),
            Text(
              'Link chưa đúng hoặc đã hết hạn',
              style: context.text.body.copyWith(fontSize: 20 * unit, color: context.colors.onSurfaceVariant),
            ),
          ]),
        TvClosed() => Text('Đã đóng mã', style: title.copyWith(fontSize: 32 * unit)),
        TvLive(:final frame, :final rotateIn) => FittedBox(
            child: Padding(
              padding: EdgeInsets.all(24 * unit),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Semantics(
                  label: 'Mã QR điểm danh',
                  child: QrImageView(
                    data: frame.qr!,
                    size: 500 * unit,
                    padding: EdgeInsets.zero,
                    backgroundColor: context.colors.surface,
                    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: fg),
                    dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: fg),
                  ),
                ),
                if (frame.code != null) ...[
                  SizedBox(height: 16 * unit),
                  Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('Mã ', style: context.text.body.copyWith(fontSize: 26 * unit, color: context.colors.onSurfaceVariant)),
                    Text(
                      '${frame.code!.substring(0, 3)} ${frame.code!.substring(3)}',
                      style: title.copyWith(fontSize: 64 * unit, letterSpacing: 2 * unit),
                    ),
                  ]),
                ],
                SizedBox(height: 12 * unit),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  RotateCodeIcon(size: 22 * unit),
                  SizedBox(width: 8 * unit),
                  Text('Đổi mã ${rotateIn}s', style: context.text.body.copyWith(fontSize: 20 * unit, color: context.colors.onSurfaceVariant)),
                ]),
              ]),
            ),
          ),
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.state, required this.unit});
  final TvState state;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final on = context.colors.onPrimary;
    final frame = switch (state) {
      TvLive(:final frame) || TvClosed(:final frame) => frame,
      _ => null,
    };
    return ColoredBox(
      color: context.colors.primary,
      child: Padding(
        padding: EdgeInsets.fromLTRB(56 * unit, 56 * unit, 56 * unit, 48 * unit),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            frame?.title ?? 'Hereby',
            style: context.text.display.copyWith(color: on, fontSize: 36 * unit),
          ),
          SizedBox(height: 8 * unit),
          if (frame != null) Text(frame.subtitle, style: context.text.body.copyWith(color: on, fontSize: 20 * unit)),
          const Spacer(),
          if (frame != null) ...[
            _Count(frame: frame, unit: unit),
            SizedBox(height: 8 * unit),
            Text('đã quét', style: context.text.body.copyWith(color: on, fontSize: 22 * unit)),
          ],
          const Spacer(),
          if (state case TvLive(:final remaining))
            Text('Còn ${VnDate.countdown(remaining)}', style: context.text.body.copyWith(color: on, fontSize: 20 * unit)),
        ]),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.frame, required this.unit});
  final TvFrame frame;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final on = context.colors.onPrimary;
    final base = context.text.display.copyWith(color: on, fontSize: 112 * unit, height: 1);
    return Semantics(
      liveRegion: true,
      label: '${frame.present} trên ${frame.total} đã quét',
      child: ExcludeSemantics(
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '${frame.present}', style: base),
          TextSpan(text: ' / ${frame.total}', style: base.copyWith(fontSize: 64 * unit, fontWeight: FontWeight.w400)),
        ])),
      ),
    );
  }
}
