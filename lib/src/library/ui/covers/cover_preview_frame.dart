import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../platform/domain/image_file_picker.dart';
import '../../../platform/ui/image_drop_target.dart';
import '../../state/covers/cover_dialog_state.dart';
import '../../state/custom_cover_providers.dart';
import 'cover_art.dart';
import 'cover_frame_art.dart';
import 'cover_frame_overlays.dart';

/// Gap between the frame and its dashed drop outline.
const double _dropOffset = KSpace.x1;

/// Share of the pan room one arrow key press moves.
const double _arrowStep = 0.05;

/// The big preview of the chosen cover: a square (a circle for an artist)
/// that shows only the preview file or a thumb, never the original image. A
/// non-square picked image can be dragged along its long axis (or moved with
/// the arrow keys while the frame has focus) under a 3 x 3 grid; on desktop
/// a dropped image file is picked.
class CoverPreviewFrame extends StatefulWidget {
  const CoverPreviewFrame({
    super.key,
    required this.kind,
    required this.itemKey,
    required this.state,
    required this.onOffset,
    required this.onDrop,
  });

  final CustomCoverKind kind;
  final String itemKey;
  final CoverDialogState state;
  final ValueChanged<double> onOffset;
  final ValueChanged<PickedImage> onDrop;

  @override
  State<CoverPreviewFrame> createState() => _CoverPreviewFrameState();
}

class _CoverPreviewFrameState extends State<CoverPreviewFrame> {
  bool _hover = false;
  final _focus = FocusNode(debugLabel: 'cover preview');
  bool _focused = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  CoverDialogState get _s => widget.state;
  bool get _circle => widget.kind == CustomCoverKind.artist;

  /// Pan room per frame side: how many frame sides the image sticks out.
  double get _roomFactor {
    final p = _s.chosenPicked?.preview;
    if (p == null) return 0;
    final long = p.width > p.height ? p.width : p.height;
    final short = p.width > p.height ? p.height : p.width;
    return long / short - 1;
  }

  bool get _horizontal {
    final p = _s.chosenPicked?.preview;
    return p != null && p.width > p.height;
  }

  void _drag(double delta, double frame) {
    final room = _roomFactor * frame;
    if (room <= 0) return;
    widget.onOffset(_s.offset - delta / room);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !_s.panPossible) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final back =
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft;
    final forward =
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight;
    if (!back && !forward) return KeyEventResult.ignored;
    widget.onOffset(_s.offset + (forward ? _arrowStep : -_arrowStep));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final frame = kHostIsSheet(context) ? 184.0 : 216.0;
    final pan = _s.panPossible;
    final radius = _circle
        ? BorderRadius.circular(frame / 2)
        : coverFrameRadius;
    Widget content = SizedBox.square(
      dimension: frame,
      child: CoverFrameArt(
        kind: widget.kind,
        itemKey: widget.itemKey,
        state: _s,
        frame: frame,
      ),
    );
    if (pan) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CoverGridPainter(
                  // White 55 % grid as in the mockup; the frame is always a picture.
                  const Color(0xFFFFFFFF).withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ],
      );
    }
    content = ClipRRect(borderRadius: radius, child: content);
    if (_hover) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                content,
                Positioned.fill(
                  child: CoverDropOverlay(
                    label: AppLocalizations.of(context).coverDropHere,
                  ),
                ),
              ],
            ),
          ),
          // Outline 2 dp, drawn 4 dp outside the frame (mockup `.drop`).
          Positioned(
            left: -_dropOffset,
            top: -_dropOffset,
            right: -_dropOffset,
            bottom: -_dropOffset,
            child: IgnorePointer(
              child: CustomPaint(
                painter: CoverDashedBorderPainter(
                  color: scheme.primary,
                  radius: coverFrameRadius.topLeft.x + _dropOffset,
                  circle: _circle,
                ),
              ),
            ),
          ),
        ],
      );
    }
    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
    final panned = !pan
        ? shadowed
        : Focus(
            focusNode: _focus,
            onKeyEvent: _key,
            onFocusChange: (f) => setState(() => _focused = f),
            child: Semantics(
              label: AppLocalizations.of(context).coverPanHint,
              focusable: true,
              focused: _focus.hasFocus,
              onIncrease: () => widget.onOffset(_s.offset + _arrowStep),
              onDecrease: () => widget.onOffset(_s.offset - _arrowStep),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _focus.requestFocus(),
                onVerticalDragUpdate: _horizontal || _s.saving
                    ? null
                    : (d) => _drag(d.delta.dy, frame),
                onHorizontalDragUpdate: !_horizontal || _s.saving
                    ? null
                    : (d) => _drag(d.delta.dx, frame),
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: KFocusRing(
                    focused: _focused,
                    radius: radius,
                    inset: 3,
                    child: shadowed,
                  ),
                ),
              ),
            ),
          );
    return ImageDropTarget(
      enabled: !_s.saving,
      onHover: (over) {
        if (mounted && _hover != over) setState(() => _hover = over);
      },
      onDrop: widget.onDrop,
      // The picture is decoration; a pannable frame keeps its own label.
      child: pan ? panned : ExcludeSemantics(child: panned),
    );
  }
}
