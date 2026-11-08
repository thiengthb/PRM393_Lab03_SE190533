import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_attend_core/theme/tokens.dart';

/// design/tokens/hereby.css (extension đọc) phải khớp tokens.dart. Lệch thì chạy lại
/// `node tool/tokens/gen_css.mjs`.
void main() {
  final css = File('../design/tokens/hereby.css').readAsStringSync();
  String hex(Color c) {
    final v = c.toARGB32();
    final rgb = (v & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final a = v >>> 24;
    return a == 255 ? '#$rgb' : '#$rgb${a.toRadixString(16).padLeft(2, '0')}';
  }

  void expectVar(String name, String value) =>
      expect(css, contains('--hb-$name: $value;'), reason: 'Chạy lại node tool/tokens/gen_css.mjs');

  test('màu Biển sâu và màu trạng thái khớp tokens.dart', () {
    const p = AppPalette.bienSau;
    expectVar('color-primary', hex(p.primary));
    expectVar('color-primary-edge', hex(p.primaryEdge));
    expectVar('color-primary-soft', hex(p.primarySoft));
    expectVar('color-on-primary-soft', hex(p.onPrimarySoft));
    expectVar('color-success', hex(AppColors.success));
    expectVar('color-warning', hex(AppColors.warning));
    expectVar('color-danger', hex(AppColors.danger));
    expectVar('color-muted-surface', hex(AppColors.mutedSurface));
    expectVar('color-border', hex(AppColors.border));
    expectVar('color-fg', hex(AppColors.fg));
  });

  test('bo góc và bố cục khớp tokens.dart', () {
    expectVar('radius-md', '${AppRadius.md.toInt()}px');
    expectVar('layout-page', '${AppLayout.page.toInt()}px');
    expectVar('layout-rail', '${AppLayout.rail.toInt()}px');
  });
}
