import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_focus_ring.dart';
import 'k_icon_button.dart';
import 'setup/dashed_outline.dart';

/// What a [KContextChip] means for the next message.
enum KContextChipState {
  /// Offered, not attached: a faint dashed "+ label"; tapping attaches it.
  suggested,

  /// Sent with the next message: tonal, with the kind icon and a ×.
  attached,

  /// Attached but unusable (its tool is off): struck through and dimmed, still
  /// removable.
  struck,
}

/// A piece of context the user can send along with a chat message.
///
/// Intent only: the chip picks height (32 on the mobile shell, 28 on the
/// desktop one), corner radius 8 and colours from [state]. The label is one
/// line cut with "…" and the chip is never wider than its parent; at large
/// text scales the label grows, the icon and the × keep their size.
///
/// Semantics: one toggle button labelled [label], toggled while attached or
/// struck, with [struckHint] as its hint while struck (so a screen reader
/// and a test can tell the state), plus the × as its own button labelled
/// [removeLabel]. The × is a [KIconButton]; there is none while suggested.
class KContextChip extends StatefulWidget {
  const KContextChip({
    super.key,
    required this.label,
    required this.icon,
    required this.state,
    required this.onTap,
    required this.onRemove,
    required this.removeLabel,
    this.struckHint,
  });

  final String label;

  /// Kind icon, shown while attached or struck.
  final IconData icon;
  final KContextChipState state;

  /// Body tapped: attaches a suggested chip; what it does on the others is
  /// the caller's call.
  final VoidCallback onTap;

  /// × tapped (attached and struck chips).
  final VoidCallback onRemove;

  /// Tooltip and screen-reader label of the × ("Bỏ thẻ" + the name).
  final String removeLabel;

  /// Screen-reader hint while [state] is struck ("Công cụ của thẻ này đang
  /// tắt").
  final String? struckHint;

  static const double _heightMobile = 32;
  static const double _heightDesktop = 28;
  static const double _dimmed = 0.45;

  @override
  State<KContextChip> createState() => _KContextChipState();
}

class _KContextChipState extends State<KContextChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium;
    final suggested = widget.state == KContextChipState.suggested;
    final struck = widget.state == KContextChipState.struck;
    final height = FormFactor.of(context) == FormFactor.desktop
        ? KContextChip._heightDesktop
        : KContextChip._heightMobile;
    final foreground = suggested
        ? scheme.onSurfaceVariant
        : scheme.onSecondaryContainer;

    final label = Text(
      suggested ? '+ ${widget.label}' : widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: style?.copyWith(
        color: foreground,
        decoration: struck ? TextDecoration.lineThrough : null,
        decorationColor: foreground,
      ),
    );
    Widget body = Padding(
      padding: EdgeInsets.only(
        left: KSpace.x2 + KSpace.x1 / 2,
        right: suggested ? KSpace.x2 + KSpace.x1 / 2 : KSpace.x1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!suggested) ...[
            Icon(widget.icon, size: KIconSize.xs, color: foreground),
            const SizedBox(width: KSpace.x1),
          ],
          Flexible(child: label),
        ],
      ),
    );
    if (struck) {
      body = Opacity(opacity: KContextChip._dimmed, child: body);
    }

    final tap = Semantics(
      button: true,
      toggled: !suggested,
      label: widget.label,
      hint: struck ? widget.struckHint : null,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: KRadius.xs,
        onFocusChange: (v) => setState(() => _focused = v),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Center(widthFactor: 1, heightFactor: 1, child: body),
        ),
      ),
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: tap),
        if (!suggested)
          KIconButton(
            icon: KIcons.close,
            size: KIconSize.xs,
            padding: const EdgeInsets.all(KSpace.x1),
            tooltip: widget.removeLabel,
            onPressed: widget.onRemove,
            color: foreground,
          ),
      ],
    );

    final shape = KShape.of(KRadius.xs);
    Widget chip = Material(
      color: suggested ? Colors.transparent : scheme.secondaryContainer,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: row,
    );
    if (suggested) {
      chip = DashedOutline(
        color: scheme.outlineVariant,
        radius: 8,
        child: chip,
      );
    }
    return KFocusRing(focused: _focused, radius: KRadius.xs, child: chip);
  }
}
