import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Text field: default, focused (viền cam 2), error (viền đỏ + một dòng lỗi), disabled.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.prefixIcon,
    this.maxLines = 1,
    this.autofillHints,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final IconData? prefixIcon;
  final int maxLines;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: context.text.label),
          const SizedBox(height: AppSpace.s4),
        ],
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          autofillHints: widget.autofillHints,
          style: context.text.body.copyWith(color: context.status.fgStrong),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: AppSize.icon20),
            constraints: const BoxConstraints(minHeight: AppSize.touch),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: AppSize.icon20),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
