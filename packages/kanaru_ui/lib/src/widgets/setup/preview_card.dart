import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../layout/form_factor.dart';
import '../../tokens/k_space.dart';
import 'k_seek_style_card.dart';

/// One card of a [KPreviewCardGroup]: a [preview] picture of the choice, its
/// [title] and a one-line [caption].
///
/// [fallback] puts a ★ at the end of the title line, [action] a button row
/// on the card while it is chosen, [onReselect] runs when the already chosen
/// card is tapped again (instead of choosing it once more).
class KPreviewOption<T> {
  const KPreviewOption({
    required this.value,
    required this.preview,
    required this.title,
    required this.caption,
    this.fallback,
    this.action,
    this.onReselect,
  });

  final T value;
  final Widget preview;
  final String title;
  final String caption;
  final KFallbackMark? fallback;
  final KCardAction? action;
  final VoidCallback? onReselect;
}

/// A single choice made by how it looks (progress bar style, layout): cards
/// in a grid whose column count the group picks itself: 2 on the mobile
/// shell, 3 on the desktop shell, 1 from 200 % text ([columnsFor]). Every card
/// is a [KSeekStyleCard]: the chosen one has a 2 px `primary` border and a
/// small tick badge. Tapping chooses at once; the arrow keys move the choice
/// and the focus while a card itself (not its ★ or action) has focus. Needs
/// at least two options.
class KPreviewCardGroup<T> extends StatefulWidget {
  const KPreviewCardGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  }) : assert(options.length >= 2, 'preview cards need at least two options');

  /// Text scale from which the cards stack in one column.
  static const double stackTextScale = 2;

  /// Columns of the grid for a [formFactor] and [textScale].
  static int columnsFor(FormFactor formFactor, double textScale) {
    if (textScale >= stackTextScale) return 1;
    return switch (formFactor) {
      FormFactor.mobile => 2,
      FormFactor.desktop => 3,
    };
  }

  final List<KPreviewOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  State<KPreviewCardGroup<T>> createState() => _KPreviewCardGroupState<T>();
}

class _KPreviewCardGroupState<T> extends State<KPreviewCardGroup<T>> {
  final List<FocusNode> _nodes = [];

  /// Keeps one focus node per option when the option count changes.
  void _syncNodes() {
    final count = widget.options.length;
    while (_nodes.length < count) {
      _nodes.add(FocusNode());
    }
    if (_nodes.length > count) {
      final extra = _nodes.sublist(count);
      _nodes.removeRange(count, _nodes.length);
      // The removed cards still hold their nodes until this frame is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in extra) {
          node.dispose();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(KPreviewCardGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final int step;
    if (key == LogicalKeyboardKey.arrowDown ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight)) {
      step = 1;
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft)) {
      step = -1;
    } else {
      return KeyEventResult.ignored;
    }
    final focused = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (focused < 0) return KeyEventResult.ignored;
    final next = focused + step;
    if (next < 0 || next >= _nodes.length) return KeyEventResult.handled;
    _nodes[next].requestFocus();
    widget.onChanged(widget.options[next].value);
    return KeyEventResult.handled;
  }

  Widget _card(int i) {
    final option = widget.options[i];
    final selected = option.value == widget.selected;
    return KSeekStyleCard(
      preview: option.preview,
      title: option.title,
      caption: option.caption,
      focusNode: _nodes[i],
      selected: selected,
      fallback: option.fallback,
      action: option.action,
      onTap: () => selected && option.onReselect != null
          ? option.onReselect!()
          : widget.onChanged(option.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = KSpace.x3;
          final columns = KPreviewCardGroup.columnsFor(
            FormFactor.of(context),
            MediaQuery.textScalerOf(context).scale(1),
          ).clamp(1, widget.options.length);
          // Floored so rounding never pushes the last card of a row to the next.
          final width = ((box.maxWidth - gap * (columns - 1)) / columns)
              .floorToDouble();
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                SizedBox(width: width, child: _card(i)),
            ],
          );
        },
      ),
    );
  }
}
