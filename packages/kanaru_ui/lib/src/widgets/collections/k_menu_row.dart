import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_chip.dart';
import '../k_gap.dart';
import '../pro_badge.dart';

/// Icon button at the end of a [KMenuRow] (for example "open in file manager").
class KMenuTrailing {
  const KMenuTrailing({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;

  /// Runs after the menu closed.
  final VoidCallback onPressed;
}

/// Chip under a [KMenuRow] (one of several targets).
class KMenuChip {
  const KMenuChip({required this.label, required this.onTap});

  final String label;

  /// Runs after the menu closed.
  final VoidCallback onTap;
}

/// One row of a [KMenuPage].
///
/// At most one of [opens], [chips] and [onTap] drives the row: [opens] shows
/// a sub-page, [chips] folds or unfolds the chips under the row, [onTap]
/// closes the menu and then runs. A row with [soonLabel] or `enabled: false`
/// is dimmed and inert.
class KMenuRow {
  const KMenuRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.onTap,
    this.opens,
    this.chips = const [],
    this.chipsExpanded = false,
    this.trailing,
    this.enabled = true,
    this.soonLabel,
    this.danger = false,
    this.proLabel,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// A picture (a cover) in place of [icon]; it should be square, about 40.
  final Widget? leading;
  final VoidCallback? onTap;
  final KMenuPage? opens;
  final List<KMenuChip> chips;
  final bool chipsExpanded;
  final KMenuTrailing? trailing;
  final bool enabled;

  /// "Coming soon" text: dims the row, which stays inert.
  final String? soonLabel;
  final bool danger;

  /// Shows a Pro badge with this text.
  final String? proLabel;

  bool get active => enabled && soonLabel == null;
}

/// A button of the sticky menu footer.
class KMenuButton {
  const KMenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;

  /// Runs after the menu closed.
  final VoidCallback onPressed;
}

/// One page of a layered menu: optional [header] (cover, name), groups of
/// rows split by lines (empty groups are skipped) and a [footer] pinned below
/// the scrolling groups. A sub-page shows `[←] title` instead of the header.
/// A group may have a heading ([groupTitles]); the header may open a sub-page
/// ([headerOpens]).
class KMenuPage {
  const KMenuPage({
    this.title,
    this.header,
    required this.groups,
    this.footer = const [],
    this.note,
    this.groupTitles = const [],
    this.headerOpens,
  });

  final String? title;
  final Widget? header;
  final List<List<KMenuRow>> groups;
  final List<KMenuButton> footer;

  /// Heading above each group by index; missing or null = none.
  final List<String?> groupTitles;

  /// Makes the [header] a button (with a `›`) that shows this page.
  final KMenuPage? headerOpens;

  /// Explanatory line above the groups (sub-pages).
  final String? note;
}

/// Row widget: icon, texts, badges, trailing button, chips.
class KMenuRowTile extends StatefulWidget {
  const KMenuRowTile({
    super.key,
    required this.row,
    required this.onActivate,
    this.autofocus = false,
  });

  final KMenuRow row;

  /// Called when the row is chosen, with the effect to run.
  final void Function(VoidCallback effect) onActivate;
  final bool autofocus;

  @override
  State<KMenuRowTile> createState() => _KMenuRowTileState();
}

class _KMenuRowTileState extends State<KMenuRowTile> {
  late bool _expanded = widget.row.chipsExpanded;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final color = row.danger ? scheme.error : scheme.onSurface;
    final soft = row.danger ? scheme.error : scheme.onSurfaceVariant;
    final foldable = row.chips.isNotEmpty;
    final VoidCallback? tap = !row.active
        ? null
        : row.opens != null
        ? () => widget.onActivate(() {})
        : foldable
        ? () => setState(() => _expanded = !_expanded)
        : () => widget.onActivate(row.onTap ?? () {});
    final trailing = row.trailing;
    return Opacity(
      opacity: row.active ? 1 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            enabled: row.active,
            child: InkWell(
              autofocus: widget.autofocus,
              borderRadius: KRadius.sm,
              onTap: tap,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: mobile
                      ? KLayout.minTarget + KSpace.x1
                      : KLayout.minTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KSpace.x4,
                    vertical: KSpace.x2,
                  ),
                  child: Row(
                    children: [
                      if (row.leading != null) ...[
                        row.leading!,
                        const KGap(KSpace.x4),
                      ] else if (row.icon != null) ...[
                        Icon(row.icon, size: 22, color: soft),
                        const KGap(KSpace.x4),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.title,
                              style: textTheme.bodyLarge?.copyWith(
                                color: color,
                              ),
                            ),
                            if (row.subtitle != null)
                              Text(
                                row.subtitle!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: soft,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (row.proLabel != null) ...[
                        const KGap(KSpace.x2),
                        ProBadge(label: row.proLabel!),
                      ],
                      if (row.soonLabel != null) ...[
                        const KGap(KSpace.x2),
                        Text(
                          row.soonLabel!,
                          style: textTheme.labelSmall?.copyWith(color: soft),
                        ),
                      ],
                      if (trailing != null) ...[
                        const KGap(KSpace.x1),
                        // Its own node, not merged into the row's.
                        Semantics(
                          container: true,
                          child: IconButton(
                            tooltip: trailing.tooltip,
                            icon: Icon(trailing.icon),
                            onPressed: row.active
                                ? () => widget.onActivate(trailing.onPressed)
                                : null,
                          ),
                        ),
                      ],
                      if (row.opens != null)
                        Icon(KIcons.chevronRight, color: soft),
                      if (foldable)
                        Icon(
                          _expanded ? KIcons.expand : KIcons.collapse,
                          color: soft,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (foldable && _expanded)
            Padding(
              padding: EdgeInsets.fromLTRB(
                row.icon == null ? KSpace.x4 : KSpace.x4 + 22 + KSpace.x4,
                0,
                KSpace.x4,
                KSpace.x2,
              ),
              child: Wrap(
                spacing: KSpace.x2,
                runSpacing: KSpace.x2,
                children: [
                  for (final chip in row.chips)
                    KChip(
                      label: Text(chip.label),
                      enabled: row.active,
                      onTap: () => widget.onActivate(chip.onTap),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
