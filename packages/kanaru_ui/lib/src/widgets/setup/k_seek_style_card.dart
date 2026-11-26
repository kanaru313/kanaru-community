import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../k_focus_ring.dart';
import 'k_seek_style_card_body.dart';
import 'k_seek_style_card_parts.dart';

export 'k_seek_style_card_parts.dart' show KCardAction, KFallbackMark;

/// Distance of the keyboard ring from the card edge, on top of its 2 px.
const double _ringOffset = 2;

/// One choice card: a [preview] picture in a lighter well, a [title] and a
/// one-line [caption].
///
/// The chosen card ([selected]) has a 2 px `primary` border and a tick badge
/// in its top-right corner. [fallback] adds a
/// ★ at the end of the title line, [action] a full-width button row on the
/// chosen card only.
///
/// Semantics: the card is one container node (selected, in a mutually
/// exclusive group, tap action); the ★ and the action are their own button
/// nodes. The keyboard ring and the group's arrow keys follow the card node
/// itself holding primary focus, never the ★ or the action inside it.
class KSeekStyleCard extends StatefulWidget {
  const KSeekStyleCard({
    super.key,
    required this.preview,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
    this.focusNode,
    this.fallback,
    this.action,
  });

  final Widget preview;
  final String title;
  final String caption;
  final bool selected;

  /// Tap, Enter or Space on the card.
  final VoidCallback onTap;

  /// Focus of the card itself (a group keeps one per card for arrow keys).
  final FocusNode? focusNode;

  /// Null: this card cannot be the fallback, no ★.
  final KFallbackMark? fallback;

  /// Shown only while [selected].
  final KCardAction? action;

  @override
  State<KSeekStyleCard> createState() => _KSeekStyleCardState();
}

class _KSeekStyleCardState extends State<KSeekStyleCard> {
  FocusNode? _own;
  late FocusNode _node = widget.focusNode ?? (_own = FocusNode());
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(KSeekStyleCard old) {
    super.didUpdateWidget(old);
    final next = widget.focusNode ?? (_own ??= FocusNode());
    if (next != _node) {
      _node.removeListener(_onFocus);
      _node = next;
      _node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _own?.dispose();
    super.dispose();
  }

  // Fires when primary focus moves between the card and the ★ / action in it.
  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final overlay = _pressed ? 0.10 : (_hovered ? 0.08 : 0.0);
    final action = widget.action;
    final fallback = widget.fallback;
    return Semantics(
      container: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      focusable: true,
      focused: _node.hasPrimaryFocus,
      label: widget.title,
      hint: widget.caption,
      onTap: widget.onTap,
      // The ring is a sibling, not a wrapper: it appears and disappears as
      // focus moves into the ★ or action, which must not rebuild them.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Actions(
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onTap();
                    return null;
                  },
                ),
              },
              // One traversal unit per card: Tab walks card, ★, action before
              // it moves to the next card.
              child: FocusTraversalGroup(
                child: Focus(
                  focusNode: _node,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: widget.onTap,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: Color.alphaBlend(
                          scheme.onSurface.withValues(alpha: overlay),
                          scheme.surfaceContainerLow,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: KRadius.lg,
                          side: BorderSide(
                            color: selected
                                ? scheme.primary
                                : const Color(0x00000000),
                            width: 2,
                          ),
                        ),
                      ),
                      child: SeekStyleCardBody(
                        preview: widget.preview,
                        title: widget.title,
                        caption: widget.caption,
                        selected: selected,
                        fallback: fallback,
                        action: action,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: KFocusRing(
                focused: _node.hasPrimaryFocus,
                radius: KRadius.lg,
                inset: 2 + _ringOffset,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
