import 'package:material_ui/material_ui.dart';

import '../tokens/k_icon_size.dart';
import '../tokens/k_layout.dart';

/// One text (or prominent) action of a `KInlineNotice`, with the semantics of
/// a button whose label stays the action's own name. Used by the notice only;
/// not exported.
class KInlineNoticeAction extends StatelessWidget {
  const KInlineNoticeAction({
    super.key,
    required this.label,
    required this.onTap,
    required this.foreground,
    required this.filled,
    required this.primary,
    this.prominent = false,
    this.busy = false,
    this.busyLabel,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onTap;

  /// Text colour on a tinted strip.
  final Color foreground;

  /// The strip is tinted: the button takes [foreground].
  final bool filled;

  /// The first action; only it can be busy, prominent or have a longer
  /// screen-reader label.
  final bool primary;
  final bool prominent;
  final bool busy;
  final String? busyLabel;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBusy = primary && busy;
    final isProminent = primary && prominent;
    final child = isBusy
        ? SizedBox.square(
            dimension: KIconSize.xs,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isProminent ? scheme.onPrimary : foreground,
            ),
          )
        : Text(label);
    final onPressed = isBusy ? null : onTap;
    final Widget button = isProminent
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, KLayout.compactButton),
            ),
            child: child,
          )
        : TextButton(
            onPressed: onPressed,
            style: filled
                ? TextButton.styleFrom(foregroundColor: foreground)
                : null,
            child: child,
          );
    return Semantics(
      container: true,
      button: true,
      enabled: true,
      onTap: onPressed,
      label: isBusy
          ? (busyLabel ?? label)
          : (primary ? (semanticsLabel ?? label) : label),
      excludeSemantics: true,
      child: button,
    );
  }
}
