import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_check_mark.dart';
import '../k_focus_ring.dart';
import '../k_gap.dart';

/// One card of a [KPreviewCardGroup]: a [preview] picture of the choice, its
/// [title] and a one-line [caption].
class KPreviewOption<T> {
  const KPreviewOption({
    required this.value,
    required this.preview,
    required this.title,
    required this.caption,
  });

  final T value;
  final Widget preview;
  final String title;
  final String caption;
}

/// A single choice made by how it looks (progress bar style, layout): cards
/// in a wrapping grid, each at least [minCardWidth] wide. The chosen card has
/// a 2 px `primary` border and a small tick badge. Tapping chooses at once;
/// the arrow keys move the choice and the focus. Needs at least two options.
class KPreviewCardGroup<T> extends StatefulWidget {
  const KPreviewCardGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  }) : assert(options.length >= 2, 'preview cards need at least two options');

  static const double minCardWidth = 220;

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
    // Roving focus: only the chosen card (the first when none is chosen) is
    // reached by Tab; the arrow keys move inside the group.
    var tabStop = widget.options.indexWhere((o) => o.value == widget.selected);
    if (tabStop < 0) tabStop = 0;
    for (var i = 0; i < count; i++) {
      _nodes[i].skipTraversal = i != tabStop;
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
    final focused = _nodes.indexWhere((n) => n.hasFocus);
    if (focused < 0) return KeyEventResult.ignored;
    final next = focused + step;
    if (next < 0 || next >= _nodes.length) return KeyEventResult.handled;
    _nodes[next].requestFocus();
    widget.onChanged(widget.options[next].value);
    return KeyEventResult.handled;
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
          final fit =
              ((box.maxWidth + gap) / (KPreviewCardGroup.minCardWidth + gap))
                  .floor();
          final columns = fit.clamp(1, widget.options.length);
          final width = (box.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                SizedBox(
                  width: width,
                  child: _PreviewCard(
                    option: widget.options[i],
                    focusNode: _nodes[i],
                    selected: widget.options[i].value == widget.selected,
                    onTap: () => widget.onChanged(widget.options[i].value),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewCard extends StatefulWidget {
  const _PreviewCard({
    required this.option,
    required this.focusNode,
    required this.selected,
    required this.onTap,
  });

  final KPreviewOption<Object?> option;
  final FocusNode focusNode;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = widget.selected;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final option = widget.option;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: option.title,
      hint: option.caption,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: KFocusRing(
        focused: _focused,
        radius: KRadius.md,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: KRadius.md,
              side: BorderSide(
                color: selected ? scheme.primary : const Color(0x00000000),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              focusNode: widget.focusNode,
              onFocusChange: (v) => setState(() => _focused = v),
              onTap: widget.onTap,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(KSpace.x3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        option.preview,
                        const KGap(KSpace.x2),
                        Text(
                          option.title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        Text(
                          option.caption,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: KSpace.x2,
                    end: KSpace.x2,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: animate ? KMotion.fast : Duration.zero,
                      curve: KMotion.emphasized,
                      child: const KCheckMark(
                        state: KCheckState.on,
                        size: 20,
                        style: KCheckMarkStyle.cover,
                      ),
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
