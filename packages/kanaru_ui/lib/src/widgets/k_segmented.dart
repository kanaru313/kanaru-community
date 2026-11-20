import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_focus_ring.dart';

/// One segment of a [KSegmented].
class KSegment<T> {
  const KSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// 2 to 4 short text values, always visible, one chosen: only the chosen
/// segment is tinted (tonal fill), no check mark. 48 dp tall on touch shells,
/// 36 on desktop.
///
/// Tab walks the segments, the arrow keys move focus to the neighbour
/// segment, Enter / Space choose the focused one. Semantics: one node per
/// segment, `selected` for the chosen, all in one mutually exclusive group.
class KSegmented<T> extends StatefulWidget {
  const KSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<KSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Spoken name of the whole group.
  final String? semanticLabel;

  @override
  State<KSegmented<T>> createState() => _KSegmentedState<T>();
}

class _MoveFocus extends Intent {
  const _MoveFocus(this.delta);
  final int delta;
}

class _KSegmentedState<T> extends State<KSegmented<T>> {
  late List<FocusNode> _nodes = _makeNodes();

  @override
  void initState() {
    super.initState();
    assert(_valid, 'a segmented control holds 2 to 4 segments');
  }

  bool get _valid => widget.segments.length >= 2 && widget.segments.length <= 4;

  List<FocusNode> _makeNodes() => [
    for (var i = 0; i < widget.segments.length; i++)
      FocusNode(debugLabel: 'KSegmented $i'),
  ];

  @override
  void didUpdateWidget(KSegmented<T> old) {
    super.didUpdateWidget(old);
    assert(_valid, 'a segmented control holds 2 to 4 segments');
    if (old.segments.length != widget.segments.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = _makeNodes();
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _move(int from, int delta) {
    final to = from + delta;
    if (to >= 0 && to < _nodes.length) _nodes[to].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = FormFactor.of(context) == FormFactor.mobile ? 48.0 : 36.0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(KSpace.x1 / 2),
        decoration: ShapeDecoration(
          color: scheme.surfaceContainerHigh,
          shape: KShape.of(KRadius.full),
        ),
        child: Row(
          children: [
            for (var i = 0; i < widget.segments.length; i++)
              Expanded(
                child: Shortcuts(
                  shortcuts: {
                    const SingleActivator(LogicalKeyboardKey.arrowLeft):
                        _MoveFocus(rtl ? 1 : -1),
                    const SingleActivator(LogicalKeyboardKey.arrowRight):
                        _MoveFocus(rtl ? -1 : 1),
                  },
                  child: Actions(
                    actions: {
                      _MoveFocus: CallbackAction<_MoveFocus>(
                        onInvoke: (intent) {
                          _move(i, intent.delta);
                          return null;
                        },
                      ),
                    },
                    child: _Segment(
                      label: widget.segments[i].label,
                      selected: widget.segments[i].value == widget.value,
                      focusNode: _nodes[i],
                      onTap: () => widget.onChanged(widget.segments[i].value),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.focusNode,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final overlay = _pressed ? 0.10 : (_hovered ? 0.08 : 0.0);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          mouseCursor: SystemMouseCursors.click,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: KFocusRing(
              focused: _focused,
              radius: KRadius.full,
              child: AnimatedContainer(
                duration: duration,
                curve: KMotion.emphasized,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: Color.alphaBlend(
                    scheme.onSurface.withValues(alpha: overlay),
                    selected
                        ? scheme.secondaryContainer
                        : const Color(0x00000000),
                  ),
                  shape: KShape.of(KRadius.full),
                ),
                padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
