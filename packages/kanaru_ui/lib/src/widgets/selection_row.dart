import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_check_mark.dart';
import 'k_gap.dart';

/// One option of a choice list, tonal rounded fill and bold title when
/// selected. No radio buttons.
///
/// Text row ([leading] null): a [KCheckMark] (ring / disc + tick) at the start,
/// single and multi choice alike. Icon row: the icon, no mark for a single
/// choice; with [multi] a [KCheckMarkStyle.plain] tick in a 24 slot on the
/// right (empty when unchosen, so titles keep their width). [multi] rows expose
/// checkbox semantics, others radio-group semantics.
class SelectionRow extends StatelessWidget {
  const SelectionRow({
    super.key,
    required this.title,
    required this.selected,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.multi = false,
    this.partial = false,
    this.plainMark = false,
    this.onTap,
  });

  final Widget title;
  final Widget? subtitle;

  /// Icon or logo; omit it and the text starts at the edge.
  final Widget? leading;
  final bool selected;

  /// A disabled row is dimmed and ignores taps.
  final bool enabled;

  /// One of several choices (checkbox semantics) instead of one of a group.
  final bool multi;

  /// Dash instead of tick: some, not all, of what this row stands for is
  /// chosen. Only meaningful with [multi].
  final bool partial;

  /// Icon-row layout without an icon of its own (the select-all row of an
  /// icon list): plain tick on the right, nothing at the start.
  final bool plainMark;
  final VoidCallback? onTap;

  static const double _checkSlot = 24;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final minHeight = FormFactor.of(context) == FormFactor.mobile
        ? KLayout.minTarget + KSpace.x2
        : KLayout.minTarget;
    final active = enabled && onTap != null;
    final iconLayout = leading != null || plainMark;
    final mixed = multi && partial;
    final state = mixed
        ? KCheckState.partial
        : selected
        ? KCheckState.on
        : KCheckState.off;
    return Semantics(
      enabled: enabled,
      selected: multi ? null : selected,
      inMutuallyExclusiveGroup: multi ? null : true,
      // Flutter asserts checked is unset while mixed.
      checked: multi && !mixed ? selected : null,
      mixed: mixed ? true : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: KMotion.fast,
          decoration: ShapeDecoration(
            shape: KShape.of(KRadius.md),
            color: selected
                ? scheme.secondaryContainer
                : const Color(0x00000000),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: KShape.of(KRadius.md),
              // M3 state layers (8 % hover, 10 % press/focus of onSurface),
              // as the mockups draw them; the theme default (4 %) is too
              // faint to see on surfaceContainerHighest menus.
              hoverColor: scheme.onSurface.withValues(alpha: 0.08),
              focusColor: scheme.onSurface.withValues(alpha: 0.10),
              highlightColor: scheme.onSurface.withValues(alpha: 0.10),
              onTap: active ? onTap : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KSpace.x4,
                    vertical: KSpace.x2,
                  ),
                  child: Row(
                    children: [
                      if (!iconLayout) ...[
                        KCheckMark(size: _checkSlot, state: state),
                        const KGap(KSpace.x3),
                      ] else if (leading != null) ...[
                        IconTheme.merge(
                          data: IconThemeData(color: scheme.onSurfaceVariant),
                          child: leading!,
                        ),
                        const KGap(KSpace.x4),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultTextStyle.merge(
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: selected ? FontWeight.w700 : null,
                              ),
                              child: title,
                            ),
                            if (subtitle != null)
                              DefaultTextStyle.merge(
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                child: subtitle!,
                              ),
                          ],
                        ),
                      ),
                      if (iconLayout && multi) ...[
                        const KGap(KSpace.x3),
                        KCheckMark(
                          size: _checkSlot,
                          state: state,
                          style: KCheckMarkStyle.plain,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
