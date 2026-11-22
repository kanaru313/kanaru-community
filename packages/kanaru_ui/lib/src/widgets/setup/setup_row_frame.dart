import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:material_ui/material_ui.dart';

import '../../layout/form_factor.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_space.dart';
import '../k_focus_ring.dart';
import '../k_gap.dart';

/// Layout shared by the rows inside a setup card: leading widget, title with
/// optional subtitle, trailing widget. 56 dp tall on mobile, 48 on desktop,
/// no background of its own (the card shows through) and no divider.
class SetupRowFrame extends StatefulWidget {
  const SetupRowFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.longPressLabel,
    this.titleStyle,
    this.sharedTrailing = false,
    this.enabled = true,
    this.comingSoon = false,
    this.soonLabel,
  }) : assert(
         !comingSoon || soonLabel != null,
         'a coming-soon row needs its label',
       ),
       assert(
         longPressLabel == null || onLongPress != null,
         'a long-press label needs a long-press action',
       );

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Long press on the row (mobile and desktop); a secondary tap (right click)
  /// runs [onSecondaryTap]. Buttons in [trailing] keep their own gestures: a
  /// long press on them does not reach the row. Wrap a button placed in
  /// [subtitle] in [RowGestureShield].
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;

  /// Name of the [onLongPress] action for screen readers (a custom action).
  final String? longPressLabel;

  /// Defaults to `bodyLarge`.
  final TextStyle? titleStyle;

  /// The trailing widget is wide and may shrink (a value text): it takes two
  /// fifths of the free width, right aligned, instead of its natural width.
  final bool sharedTrailing;

  /// False dims the row (0.5) and ignores taps; semantics report it disabled.
  final bool enabled;

  /// A feature that is not built yet: dimmed, never tappable, [soonLabel] in
  /// place of [trailing].
  final bool comingSoon;

  /// Text of the coming-soon marker (the caller localises it).
  final String? soonLabel;

  /// Minimum row height for the current form factor.
  static double minHeight(BuildContext context) =>
      FormFactor.of(context) == FormFactor.mobile
      ? KLayout.minTarget + KSpace.x2
      : KLayout.minTarget;

  @override
  State<SetupRowFrame> createState() => _SetupRowFrameState();
}

class _SetupRowFrameState extends State<SetupRowFrame> {
  bool _focused = false;

  @override
  void didUpdateWidget(SetupRowFrame old) {
    super.didUpdateWidget(old);
    // A row that stops being tappable no longer has focus to show.
    if (!widget.enabled || widget.comingSoon) _focused = false;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pressable = w.onLongPress != null || w.onSecondaryTap != null;
    final trailing = pressable && w.trailing != null
        ? RowGestureShield(child: w.trailing!)
        : w.trailing;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: SetupRowFrame.minHeight(context)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x4,
          vertical: KSpace.x2,
        ),
        child: Row(
          children: [
            if (w.leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: scheme.onSurfaceVariant),
                child: w.leading!,
              ),
              const KGap(KSpace.x4),
            ],
            Expanded(
              flex: w.sharedTrailing ? 3 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: w.titleStyle ?? textTheme.bodyLarge,
                    child: w.title,
                  ),
                  if (w.subtitle != null)
                    DefaultTextStyle.merge(
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      child: w.subtitle!,
                    ),
                ],
              ),
            ),
            if (w.comingSoon) ...[
              const KGap(KSpace.x3),
              Text(
                w.soonLabel!,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ] else if (w.trailing != null) ...[
              const KGap(KSpace.x3),
              if (w.sharedTrailing)
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing!,
                  ),
                )
              else
                trailing!,
            ],
          ],
        ),
      ),
    );
    final active = w.enabled && !w.comingSoon;
    if (!active) {
      return MergeSemantics(
        child: Semantics(
          enabled: false,
          child: Opacity(opacity: 0.5, child: content),
        ),
      );
    }
    final Widget row = w.onTap == null
        ? content
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: w.onTap,
              onFocusChange: (v) => setState(() => _focused = v),
              child: KFocusRing(
                focused: _focused,
                radius: BorderRadius.zero,
                child: content,
              ),
            ),
          );
    if (!pressable) return row;
    final label = w.longPressLabel;
    return Semantics(
      customSemanticsActions: {
        if (label != null && w.onLongPress != null)
          CustomSemanticsAction(label: label): w.onLongPress!,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: w.onLongPress,
        onSecondaryTap: w.onSecondaryTap,
        child: row,
      ),
    );
  }
}

/// Keeps a long press on a button inside a [SetupRowFrame] from reaching the
/// row's own long-press action: the nearest recogniser wins and does nothing.
class RowGestureShield extends StatelessWidget {
  const RowGestureShield({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onLongPress: () {}, child: child);
}
