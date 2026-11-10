import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'feedback.dart';

/// Desktop building blocks (Windows app, web admin, student web on a laptop).
///
/// Layout rules (thienui, chosen 09/11): a white top bar with the page title and the page
/// actions, content on the cool grey background with 20 px padding, flat bordered cards,
/// data in tables with hover and sort, details in a panel on the right instead of a new page,
/// 30 px controls, keyboard hints shown next to the action they trigger.

/// Small keyboard hint shown inside or next to a button, e.g. `Ctrl ↵`.
class Kbd extends StatelessWidget {
  const Kbd(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: c.surfaceContainerHighest,
          border: Border.all(color: c.outlineVariant, width: AppSize.border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(label, style: context.text.caption.copyWith(fontSize: 11, height: 1.3)),
      ),
    );
  }
}

/// White bar at the top of a desktop page: optional back arrow, title, subtitle, actions.
class DeskTopBar extends StatelessWidget {
  const DeskTopBar({super.key, required this.title, this.subtitle, this.onBack, this.actions = const [], this.leading});

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Shown before the title (breadcrumb, icon).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.outlineVariant, width: AppSize.border)),
      ),
      child: Row(children: [
        if (onBack != null) ...[
          IconButton(
            tooltip: 'Quay lại',
            onPressed: onBack,
            icon: Icon(LucideIcons.arrowLeft, size: AppSize.icon20, color: context.status.fgStrong),
          ),
          const SizedBox(width: AppSpace.s4),
        ],
        if (leading != null) ...[leading!, const SizedBox(width: AppSpace.s8)],
        Flexible(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(
              header: true,
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.title.copyWith(fontSize: 17)),
            ),
            if (subtitle != null)
              Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.caption),
          ]),
        ),
        const SizedBox(width: AppSpace.s16),
        const Spacer(),
        for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: AppSpace.s8), actions[i]],
      ]),
    );
  }
}

/// A full desktop page: [DeskTopBar] over the body, with an optional detail panel on the right.
class DeskPage extends StatelessWidget {
  const DeskPage({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    required this.body,
    this.side,
    this.scroll = false,
    this.maxWidth,
    this.padding = const EdgeInsets.all(AppSpace.s20),
    this.banner,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget body;

  /// Detail panel on the right ([DeskSidePanel]); null hides it.
  final Widget? side;

  /// true: the body scrolls as one column (settings, forms). false: the body fills the height
  /// and manages its own scrolling (tables, split views).
  final bool scroll;
  final double? maxWidth;
  final EdgeInsets padding;

  /// Full-width strip under the top bar (offline, errors).
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    Widget content = scroll
        ? SingleChildScrollView(
            padding: padding,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth ?? AppLayout.page), child: body),
            ),
          )
        : Padding(padding: padding, child: body);
    if (!scroll && maxWidth != null) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: content),
      );
    }
    return Scaffold(
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DeskTopBar(title: title, subtitle: subtitle, onBack: onBack, actions: actions),
        ?banner,
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: content),
            ?side,
          ]),
        ),
      ]),
    );
  }
}

/// Flat bordered card with an optional header row (title, count, trailing actions).
class DeskCard extends StatelessWidget {
  const DeskCard({
    super.key,
    this.title,
    this.count,
    this.trailing = const [],
    required this.child,
    this.padding = EdgeInsets.zero,
    this.expand = false,
    this.header,
  });

  final String? title;
  final int? count;
  final List<Widget> trailing;
  final Widget child;
  final EdgeInsets padding;

  /// true: the child fills the remaining height of the card (tables, lists).
  final bool expand;

  /// Custom header content instead of [title] (filters, tabs).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasHeader = title != null || header != null || trailing.isNotEmpty;
    final body = Padding(padding: padding, child: child);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant, width: AppSize.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: [
        if (hasHeader)
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16, vertical: AppSpace.s8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.outlineVariant, width: AppSize.border))),
            child: Row(children: [
              if (header != null)
                Expanded(child: header!)
              else ...[
                Semantics(header: true, child: Text(title!, style: context.text.section)),
                if (count != null) ...[const SizedBox(width: AppSpace.s8), CountBadge(count!)],
                const Spacer(),
              ],
              for (var i = 0; i < trailing.length; i++) ...[if (i > 0 || header != null) const SizedBox(width: AppSpace.s8), trailing[i]],
            ]),
          ),
        if (expand) Expanded(child: body) else body,
      ]),
    );
  }
}

/// Small count next to a heading. [tone] null = neutral.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.warning = false});
  final int count;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final st = context.status;
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: warning ? st.warningSoft : c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$count', style: context.text.caption.copyWith(color: warning ? st.warning : c.onSurfaceVariant, fontWeight: FontWeight.w600)),
    );
  }
}

/// Compact search box (30 px) for table headers and top bars.
class DeskSearchField extends StatelessWidget {
  const DeskSearchField({super.key, required this.hint, required this.onChanged, this.width = 240, this.shortcut, this.focusNode, this.controller});

  final String hint;
  final ValueChanged<String> onChanged;
  final double width;
  final String? shortcut;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c.outlineVariant, width: AppSize.border),
    );
    return SizedBox(
      width: width,
      height: 32,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: context.text.bodySm.copyWith(color: context.status.fgStrong),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: context.text.bodySm,
          filled: true,
          fillColor: c.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s8, vertical: 8),
          prefixIcon: Icon(LucideIcons.search, size: 15, color: c.onSurfaceVariant),
          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIcon: shortcut == null ? null : Padding(padding: const EdgeInsets.only(right: 6), child: Center(widthFactor: 1, child: Kbd(shortcut!))),
          suffixIconConstraints: const BoxConstraints(minHeight: 32),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(borderSide: BorderSide(color: c.primary, width: 1.5)),
        ),
      ),
    );
  }
}

/// One column of a [DeskTable].
class DeskColumn<T> {
  const DeskColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.width,
    this.sortBy,
    this.alignEnd = false,
  });

  final String label;
  final Widget Function(BuildContext context, T row) cell;

  /// Share of the free width. Ignored when [width] is set.
  final int flex;
  final double? width;

  /// Makes the header clickable to sort by this value.
  final Comparable<Object?> Function(T row)? sortBy;
  final bool alignEnd;
}

/// Data table for desktop: sticky header, hover highlight, click to select, sort by column.
/// Sorting and hover are view state only; filtering and counting stay in the ViewModel.
class DeskTable<T> extends StatefulWidget {
  const DeskTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onTap,
    this.isSelected,
    this.rowLabel,
    this.emptyMessage = 'Trống',
    this.emptyIcon = LucideIcons.inbox,
    this.rowHeight = 44,
    this.shrinkWrap = false,
  });

  final List<DeskColumn<T>> columns;
  final List<T> rows;
  final ValueChanged<T>? onTap;
  final bool Function(T row)? isSelected;

  /// Screen-reader label of a row (also what ARTEMIS reads first).
  final String Function(T row)? rowLabel;
  final String emptyMessage;
  final IconData emptyIcon;
  final double rowHeight;

  /// true: as tall as its rows (inside a scrolling page). false: fills the height and scrolls.
  final bool shrinkWrap;

  @override
  State<DeskTable<T>> createState() => _DeskTableState<T>();
}

class _DeskTableState<T> extends State<DeskTable<T>> {
  int? _sort;
  bool _asc = true;
  int? _hover;

  List<T> get _rows {
    final i = _sort;
    if (i == null || widget.columns[i].sortBy == null) return widget.rows;
    final by = widget.columns[i].sortBy!;
    final list = [...widget.rows]..sort((a, b) => Comparable.compare(by(a), by(b)));
    return _asc ? list : list.reversed.toList();
  }

  Widget _cell(DeskColumn<T> col, Widget child) {
    final aligned = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
      child: Align(alignment: col.alignEnd ? Alignment.centerRight : Alignment.centerLeft, child: child),
    );
    return col.width != null ? SizedBox(width: col.width, child: aligned) : Expanded(flex: col.flex, child: aligned);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final rows = _rows;
    final header = Container(
      height: 36,
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: c.outlineVariant, width: AppSize.border)),
      ),
      child: Row(children: [
        for (var i = 0; i < widget.columns.length; i++)
          _cell(
            widget.columns[i],
            widget.columns[i].sortBy == null
                ? Text(widget.columns[i].label, style: context.text.caption.copyWith(fontWeight: FontWeight.w500))
                : InkWell(
                    onTap: () => setState(() {
                      if (_sort == i) {
                        _asc = !_asc;
                      } else {
                        _sort = i;
                        _asc = true;
                      }
                    }),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.columns[i].label, style: context.text.caption.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 2),
                      Icon(
                        _sort == i ? (_asc ? LucideIcons.chevronUp : LucideIcons.chevronDown) : LucideIcons.chevronsUpDown,
                        size: 12,
                        color: c.onSurfaceVariant,
                      ),
                    ]),
                  ),
          ),
      ]),
    );
    Widget row(int i) {
      final r = rows[i];
      final selected = widget.isSelected?.call(r) ?? false;
      final bg = selected
          ? c.primaryContainer
          : (_hover == i ? c.surfaceContainerHighest.withValues(alpha: 0.55) : Colors.transparent);
      final content = Container(
        height: widget.rowHeight,
        decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.6), width: AppSize.border)),
        ),
        child: Row(children: [for (final col in widget.columns) _cell(col, DefaultTextStyle.merge(style: context.text.bodySm.copyWith(color: st.fgStrong), child: col.cell(context, r)))]),
      );
      return MouseRegion(
        onEnter: (_) => setState(() => _hover = i),
        onExit: (_) => setState(() => _hover = null),
        cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: Semantics(
          button: widget.onTap != null,
          selected: selected,
          label: widget.rowLabel?.call(r),
          onTap: widget.onTap == null ? null : () => widget.onTap!(r),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap == null ? null : () => widget.onTap!(r),
            child: content,
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      final empty = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s24),
        child: EmptyState(message: widget.emptyMessage, icon: widget.emptyIcon),
      );
      return Column(mainAxisSize: widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        if (widget.shrinkWrap) empty else Expanded(child: SingleChildScrollView(child: empty)),
      ]);
    }
    if (widget.shrinkWrap) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        for (var i = 0; i < rows.length; i++) row(i),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      header,
      Expanded(child: ListView.builder(itemCount: rows.length, itemBuilder: (_, i) => row(i))),
    ]);
  }
}

/// Detail panel on the right edge of a desktop page (400 px).
class DeskSidePanel extends StatelessWidget {
  const DeskSidePanel({super.key, required this.title, this.subtitle, required this.child, this.footer, this.onClose, this.width = 400});

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onClose;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(left: BorderSide(color: c.outlineVariant, width: AppSize.border)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          height: 56,
          padding: const EdgeInsets.only(left: AppSpace.s16, right: AppSpace.s8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.outlineVariant, width: AppSize.border))),
          child: Row(children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.title)),
                if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.caption),
              ]),
            ),
            if (onClose != null)
              IconButton(tooltip: 'Đóng', onPressed: onClose, icon: Icon(LucideIcons.x, size: 18, color: c.onSurfaceVariant)),
          ]),
        ),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpace.s16), child: child)),
        if (footer != null)
          Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.outlineVariant, width: AppSize.border))),
            child: footer,
          ),
      ]),
    );
  }
}

/// Label / value pairs in a detail panel.
class DeskFacts extends StatelessWidget {
  const DeskFacts(this.facts, {super.key, this.labelWidth = 110});
  final List<(String, String)> facts;
  final double labelWidth;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (k, v) in facts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: labelWidth, child: Text(k, style: context.text.bodySm)),
              Expanded(child: Text(v, style: context.text.bodySm.copyWith(color: context.status.fgStrong))),
            ]),
          ),
      ]);
}

/// A row in a desktop card list: icon tile, title, subtitle, trailing; highlights on hover.
class DeskListItem extends StatefulWidget {
  const DeskListItem({super.key, this.icon, this.iconColor, this.iconBackground, required this.title, this.subtitle, this.trailing, this.onTap, this.leading, this.dense = false});

  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  State<DeskListItem> createState() => _DeskListItemState();
}

class _DeskListItemState extends State<DeskListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final st = context.status;
    final lead = widget.leading ??
        (widget.icon == null
            ? null
            : Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: widget.iconBackground ?? c.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Icon(widget.icon, size: 16, color: widget.iconColor ?? c.onSurfaceVariant),
              ));
    final row = Container(
      color: _hover && widget.onTap != null ? c.surfaceContainerHighest.withValues(alpha: 0.5) : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: AppSpace.s16, vertical: widget.dense ? 8 : 10),
      child: Row(children: [
        if (lead != null) ...[lead, const SizedBox(width: AppSpace.s12)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySm.copyWith(color: st.fgStrong, fontWeight: FontWeight.w500)),
            if (widget.subtitle != null) Text(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.caption),
          ]),
        ),
        if (widget.trailing != null) ...[const SizedBox(width: AppSpace.s12), widget.trailing!],
      ]),
    );
    if (widget.onTap == null) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        onTap: widget.onTap,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: row),
      ),
    );
  }
}

/// Keyboard shortcuts for a desktop page. Keys only fire when no text field has focus,
/// a page-level Focus takes the keys when nothing else has focus.
class DeskShortcuts extends StatelessWidget {
  const DeskShortcuts({super.key, required this.bindings, required this.child});

  final Map<ShortcutActivator, VoidCallback> bindings;
  final Widget child;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
        bindings: bindings,
        child: Focus(autofocus: true, child: child),
      );
}
