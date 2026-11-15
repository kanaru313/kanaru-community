import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import 'k_check_mark_painter.dart';

/// Selection state of a [KCheckMark].
enum KCheckState { off, on, partial }

/// Where the mark sits: [surface] on a plain row, [cover] over album art
/// (white ring so it stays visible on any image), [plain] a bare `primary`
/// tick (no ring, disc or pulse) for icon rows.
enum KCheckMarkStyle { surface, cover, plain }

/// Animated selection mark: ring when off, primary disc with a drawn tick
/// when on, disc with a dash when partial (the tick morphs into the dash).
///
/// The [KCheckMarkStyle.plain] style draws only the tick (and the dash when
/// partial) with the same timing.
///
/// Painting only, no semantics: the owning row exposes them. The pulse ring
/// plays only when [state] changes after the first build, so a long list
/// never flashes on scroll. With `MediaQuery.disableAnimations` every change
/// jumps to its end state.
class KCheckMark extends StatefulWidget {
  const KCheckMark({
    super.key,
    required this.state,
    this.size = 24,
    this.style = KCheckMarkStyle.surface,
  });

  final KCheckState state;
  final double size;
  final KCheckMarkStyle style;

  @override
  State<KCheckMark> createState() => _KCheckMarkState();
}

class _KCheckMarkState extends State<KCheckMark> with TickerProviderStateMixin {
  static const _morphDuration = Duration(milliseconds: 260);

  late final AnimationController _progress;
  late final AnimationController _morph;
  bool _reversing = false;
  bool _pulse = false;

  bool _selected(KCheckState s) => s != KCheckState.off;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: KMotion.checkOn,
      reverseDuration: KMotion.checkOff,
      value: _selected(widget.state) ? 1 : 0,
    );
    _morph = AnimationController(
      vsync: this,
      duration: _morphDuration,
      value: widget.state == KCheckState.partial ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(KCheckMark old) {
    super.didUpdateWidget(old);
    final from = old.state;
    final to = widget.state;
    if (from == to) return;
    final instant = MediaQuery.disableAnimationsOf(context);
    final morphTarget = to == KCheckState.partial ? 1.0 : 0.0;
    final wasSelected = _selected(from);
    final isSelected = _selected(to);
    _pulse = false;
    if (wasSelected == isSelected) {
      // on <-> partial: disc stays, tick <-> dash.
      if (instant) {
        _morph.value = morphTarget;
      } else {
        _morph.animateTo(morphTarget);
      }
    } else if (isSelected) {
      _morph.value = morphTarget; // coming from off: no morph to play
      _reversing = false;
      if (instant) {
        _progress.value = 1;
      } else {
        _pulse = widget.style != KCheckMarkStyle.plain;
        _progress.forward();
      }
    } else {
      _reversing = true;
      if (instant) {
        _progress.value = 0;
      } else {
        _progress.reverse();
      }
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cover = widget.style == KCheckMarkStyle.cover;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: KCheckMarkPainter(
            progress: _progress,
            morph: _morph,
            reversing: _reversing,
            tickOnly: widget.style == KCheckMarkStyle.plain,
            pulse: _pulse,
            ringColor: cover
                ? Colors.white.withValues(alpha: 0.9)
                : cs.outline.withValues(alpha: 0.6),
            discColor: cs.primary,
            tickColor: widget.style == KCheckMarkStyle.plain
                ? cs.primary
                : cs.onPrimary,
          ),
        ),
      ),
    );
  }
}
