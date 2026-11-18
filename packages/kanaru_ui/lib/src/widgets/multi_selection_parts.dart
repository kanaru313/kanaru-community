import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_gap.dart';
import 'selection_picker.dart';

/// Top row of a multi picker, e.g. "Playlist mới…". Not a choice: it has no
/// mark. [onPressed] may return a new option, which is inserted right below
/// the row and selected.
class MultiSelectionAction<T> {
  const MultiSelectionAction({
    required this.title,
    required this.onPressed,
    this.leading,
  });

  final Widget title;

  /// Tile before the title; defaults to a `secondaryContainer` tile with `add`.
  final Widget? leading;
  final Future<SelectionOption<T>?> Function(BuildContext context) onPressed;
}

/// Row of a [MultiSelectionAction]: button semantics, no mark slot.
class MultiSelectionActionRow<T> extends StatelessWidget {
  const MultiSelectionActionRow({
    super.key,
    required this.action,
    required this.onTap,
  });

  final MultiSelectionAction<T> action;

  /// Null while the action is running.
  final VoidCallback? onTap;

  static const double _tile = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: KShape.of(KRadius.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: mobile
                  ? KLayout.minTarget + KSpace.x2
                  : KLayout.minTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KSpace.x4,
                vertical: KSpace.x2,
              ),
              child: Row(
                children: [
                  action.leading ??
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: KRadius.xs,
                        ),
                        child: SizedBox.square(
                          dimension: _tile,
                          child: Icon(
                            KIcons.add,
                            size: KIconSize.md,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                  const KGap(KSpace.x4),
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodyLarge,
                      child: action.title,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A button label replaced by a small progress ring, at the label's size so
/// the button does not change width while it works. The label stays in the
/// semantics tree (the ring is not).
class BusyButtonLabel extends StatelessWidget {
  const BusyButtonLabel({super.key, required this.label});

  final String label;

  static const double _ring = KIconSize.xs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          maintainSemantics: true,
          child: Text(label),
        ),
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: _ring,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Title and optional subtitle above the rows of a multi picker.
class MultiSelectionHeader extends StatelessWidget {
  const MultiSelectionHeader({super.key, required this.title, this.subtitle});

  final Widget title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x6,
            KSpace.x4,
            KSpace.x6,
            KSpace.x1,
          ),
          child: DefaultTextStyle.merge(
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            child: title,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              0,
              KSpace.x6,
              KSpace.x2,
            ),
            child: DefaultTextStyle.merge(
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              child: subtitle!,
            ),
          ),
      ],
    );
  }
}
