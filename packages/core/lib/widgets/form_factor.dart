import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Which layout family a screen uses. Chosen by platform first, width second:
/// the Windows app is always [desktop] (even in a small window), the Android app is always
/// [phone], the web admin is always [desktop], the student web follows the window width.
enum FormFactor { phone, desktop }

/// How an app picks its [FormFactor]. Set once at the top of each app.
enum FormFactorPolicy {
  /// Lecturer app: Windows → desktop, Android → phone, web (test builds) → by width.
  lecturerApp,

  /// Student web: by width (phone browser or laptop browser).
  byWidth,

  /// Web admin: always desktop.
  alwaysDesktop,
}

/// The lecturer desktop layout (side nav, code panel, class table) needs about 1100 px, the
/// minimum the Windows window keeps; narrower lecturer web windows use the phone layout (LOI-21).
const double lecturerDesktopMinWidth = 1100;

FormFactor resolveFormFactor(FormFactorPolicy policy, double width, {TargetPlatform? platform, bool? isWeb}) {
  final web = isWeb ?? kIsWeb;
  final p = platform ?? defaultTargetPlatform;
  final byWidth = AppLayout.isWide(width) ? FormFactor.desktop : FormFactor.phone;
  return switch (policy) {
    FormFactorPolicy.alwaysDesktop => FormFactor.desktop,
    FormFactorPolicy.byWidth => byWidth,
    FormFactorPolicy.lecturerApp => web
        ? (width >= lecturerDesktopMinWidth ? FormFactor.desktop : FormFactor.phone)
        : (p == TargetPlatform.windows || p == TargetPlatform.linux || p == TargetPlatform.macOS)
            ? FormFactor.desktop
            : FormFactor.phone,
  };
}

/// Puts the resolved [FormFactor] in the tree. Place it in `MaterialApp.builder`.
class FormFactorScope extends InheritedWidget {
  const FormFactorScope({super.key, required this.value, required super.child});

  final FormFactor value;

  /// Resolves the policy against the current window and wraps [child].
  static Widget of(FormFactorPolicy policy, {required Widget child}) => Builder(
        builder: (context) => FormFactorScope(
          value: resolveFormFactor(policy, MediaQuery.sizeOf(context).width),
          child: child,
        ),
      );

  static FormFactor? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FormFactorScope>()?.value;

  @override
  bool updateShouldNotify(FormFactorScope oldWidget) => oldWidget.value != value;
}

extension FormFactorContext on BuildContext {
  FormFactor get formFactor =>
      FormFactorScope.maybeOf(this) ??
      (AppLayout.isWide(MediaQuery.sizeOf(this).width) ? FormFactor.desktop : FormFactor.phone);

  bool get isDesktop => formFactor == FormFactor.desktop;
}
