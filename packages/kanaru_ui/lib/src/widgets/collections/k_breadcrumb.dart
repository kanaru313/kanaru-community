import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// One level of a [KBreadcrumb].
class KBreadcrumbSegment {
  const KBreadcrumbSegment({required this.label, this.onTap});

  final String label;

  /// Jumps to this level; null for a level that cannot be opened.
  final VoidCallback? onTap;
}

/// Path strip. The last segment is the open level (bold).
///
/// Desktop with more than four levels keeps the first and the last three and
/// joins the rest in a "…" button. Mobile shows up to two levels in full;
/// deeper paths show "…" (a tonal button) then the open level. "…" calls
/// [onShowHidden] with the hidden levels in order; the caller lists them
/// (a selection picker) and jumps.
class KBreadcrumb extends StatelessWidget {
  const KBreadcrumb({
    super.key,
    required this.segments,
    required this.onShowHidden,
    required this.hiddenTooltip,
  });

  final List<KBreadcrumbSegment> segments;
  final ValueChanged<List<KBreadcrumbSegment>> onShowHidden;

  /// Name of the "..." button for screen readers and tooltips.
  final String hiddenTooltip;

  /// Segments shown and the hidden run, by shell.
  ({
    List<KBreadcrumbSegment> head,
    List<KBreadcrumbSegment> hidden,
    List<KBreadcrumbSegment> tail,
  })
  _split(bool mobile) {
    final n = segments.length;
    if (mobile) {
      if (n <= 2) return (head: const [], hidden: const [], tail: segments);
      return (
        head: const [],
        hidden: segments.sublist(0, n - 1),
        tail: [segments.last],
      );
    }
    if (n <= 4) return (head: const [], hidden: const [], tail: segments);
    return (
      head: [segments.first],
      hidden: segments.sublist(1, n - 3),
      tail: segments.sublist(n - 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final parts = _split(mobile);
    final scheme = Theme.of(context).colorScheme;
    final children = <Widget>[];

    void add(Widget w) {
      if (children.isNotEmpty) {
        children.add(
          Icon(KIcons.chevronRight, size: 16, color: scheme.onSurfaceVariant),
        );
      }
      children.add(w);
    }

    Widget segment(KBreadcrumbSegment s) =>
        _Segment(segment: s, current: identical(s, segments.last));

    for (final s in parts.head) {
      add(Flexible(child: segment(s)));
    }
    if (parts.hidden.isNotEmpty) {
      add(
        _MoreButton(
          tonal: mobile,
          tooltip: hiddenTooltip,
          onTap: () => onShowHidden(parts.hidden),
        ),
      );
    }
    for (final s in parts.tail) {
      add(Flexible(child: segment(s)));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// Touch target: 48 on the mobile shell, 40 on desktop.
double _minHeight(BuildContext context) =>
    FormFactor.of(context) == FormFactor.mobile
    ? KLayout.minTarget
    : KLayout.minTargetDesktop;

class _Segment extends StatelessWidget {
  const _Segment({required this.segment, required this.current});

  final KBreadcrumbSegment segment;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: current ? FontWeight.w800 : FontWeight.w500,
      color: current ? scheme.onSurface : scheme.onSurfaceVariant,
    );
    final text = Text(
      segment.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    return Semantics(
      button: segment.onTap != null && !current,
      child: InkWell(
        borderRadius: KRadius.sm,
        onTap: current ? null : segment.onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _minHeight(context)),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
              child: text,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({
    required this.tonal,
    required this.onTap,
    required this.tooltip,
  });

  final bool tonal;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const label = Icon(KIcons.moreHoriz, size: 20);
    return Tooltip(
      message: tooltip ?? '',
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: tooltip != null,
        child: Material(
          color: tonal ? scheme.secondaryContainer : const Color(0x00000000),
          shape: KShape.of(KRadius.full),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: _minHeight(context),
                minWidth: _minHeight(context),
              ),
              child: const Center(widthFactor: 1, child: label),
            ),
          ),
        ),
      ),
    );
  }
}
