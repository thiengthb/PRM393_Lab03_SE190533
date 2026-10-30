import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/account_viewmodels.dart';
import '../../widgets/widgets.dart';

/// Khung 4 tab của app giảng viên (Bottom navigation, Figma 5:220).
class LecturerShell extends ConsumerWidget {
  const LecturerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lên lịch nhắc slot mỗi khi lịch hoặc cài đặt nhắc đổi.
    ref.watch(reminderSchedulerProvider);
    return Scaffold(
      body: shell,
      bottomNavigationBar: QaBottomNav(
        index: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
