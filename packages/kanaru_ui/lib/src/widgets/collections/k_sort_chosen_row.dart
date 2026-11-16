import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_drag_handle.dart';
import '../k_gap.dart';
import '../k_icon_button.dart';
import 'k_sort_dialog_rows.dart' show sortRowGap;

/// A chosen criterion: handle (hidden with one criterion) · number disc ·
/// name · direction button · remove button. Alt + Up / Alt + Down on any
/// control inside it ask [onMoveBy] to move the row by -1 / +1.
class SortChosenRow extends StatelessWidget {
  const SortChosenRow({
    super.key,
    required this.index,
    required this.name,
    required this.descending,
    required this.dragLabel,
    required this.flipTooltip,
    required this.flipSemantics,
    required this.removeLabel,
    required this.onFlip,
    required this.onRemove,
    required this.onMoveBy,
    required this.canReorder,
  });

  final int index;
  final String name;
  final bool descending;
  final bool canReorder;
  final String dragLabel;
  final String flipTooltip;
  final String flipSemantics;
  final String removeLabel;
  final VoidCallback onFlip;

  /// Null when this is the only criterion (the button is disabled).
  final VoidCallback? onRemove;
  final ValueChanged<int> onMoveBy;

  static const double _disc = 22;

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      onMoveBy(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      onMoveBy(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = scheme.onSecondaryContainer;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _key,
      child: Padding(
        padding: const EdgeInsets.only(bottom: sortRowGap),
        child: Semantics(
          label: '${index + 1}. $name',
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: scheme.secondaryContainer,
              shape: KShape.of(KRadius.md),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: IconTheme.merge(
                data: IconThemeData(color: fg),
                child: Row(
                  children: [
                    if (canReorder)
                      KDragHandle(
                        index: index,
                        compact: true,
                        iconSize: KIconSize.sm,
                        semanticLabel: dragLabel,
                      )
                    else
                      const KGap(KSpace.x2),
                    ExcludeSemantics(
                      child: Container(
                        width: _disc,
                        height: _disc,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: text.labelMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const KGap(KSpace.x2),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    KIconButton(
                      tooltip: flipTooltip,
                      semanticLabel: flipSemantics,
                      icon: descending ? KIcons.sortDesc : KIcons.sortAsc,
                      size: KIconSize.sm,
                      color: fg,
                      padding: const EdgeInsets.all(KSpace.x2),
                      onPressed: onFlip,
                    ),
                    KIconButton(
                      tooltip: removeLabel,
                      icon: KIcons.close,
                      size: KIconSize.sm,
                      color: fg,
                      padding: const EdgeInsets.all(KSpace.x2),
                      onPressed: onRemove,
                    ),
                    const KGap(KSpace.x1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
