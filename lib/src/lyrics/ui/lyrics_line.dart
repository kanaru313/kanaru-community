import 'package:flutter/foundation.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import 'lyrics_gap_mark.dart';
import 'lyrics_text_styles.dart';

/// Scale of the current line.
const double _currentScale = 1.02;

/// Horizontal room a line keeps inside its hover shape; the view takes it
/// off its own side padding so the text lines up with the area's margin.
const double lyricsLineInset = KSpace.x3;

/// `m:ss` of [time], for the seek hint.
String lyricsClock(Duration time) {
  final seconds = time.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// One line of synced lyrics, line [index] of its list. Every built line
/// listens to the one [active] index and rebuilds only when it becomes or
/// stops being the current line, never on a position tick: a line change
/// rebuilds two lines. Pressing it seeks to the line. A timed blank line is a
/// gap (three music notes). Its own repaint boundary keeps a scroll past it, or a
/// neighbour changing style, from laying the text out again.
class LyricsLine extends StatefulWidget {
  const LyricsLine({
    super.key,
    required this.index,
    required this.line,
    required this.active,
    required this.onTap,
    required this.size,
    required this.dim,
    required this.align,
  });

  final int index;
  final LyricLine line;

  /// Index of the current line of the list, -1 for none.
  final ValueListenable<int> active;
  final VoidCallback onTap;
  final double size;
  final LyricsDim dim;
  final LyricsAlign align;

  @override
  State<LyricsLine> createState() => _LyricsLineState();
}

class _LyricsLineState extends State<LyricsLine> {
  late bool _current = _isCurrent();

  bool _isCurrent() => widget.active.value == widget.index;

  @override
  void initState() {
    super.initState();
    widget.active.addListener(_onActive);
  }

  @override
  void didUpdateWidget(LyricsLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      oldWidget.active.removeListener(_onActive);
      widget.active.addListener(_onActive);
    }
    _current = _isCurrent();
  }

  @override
  void dispose() {
    widget.active.removeListener(_onActive);
    super.dispose();
  }

  void _onActive() {
    final current = _isCurrent();
    if (current != _current) setState(() => _current = current);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.slow;
    final centered = widget.align == LyricsAlign.center;
    final isCurrent = _current;
    final style = lyricsLineStyle(
      context,
      size: widget.size,
      current: isCurrent,
      dim: widget.dim,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x1),
      child: RepaintBoundary(
        child: Semantics(
          button: true,
          selected: isCurrent,
          onTapHint: l10n.lyricsSeekHint(lyricsClock(widget.line.time)),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: KRadius.md,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: lyricsLineInset,
                vertical: KSpace.x2,
              ),
              child: AnimatedScale(
                scale: isCurrent ? _currentScale : 1,
                alignment: centered ? Alignment.center : Alignment.centerLeft,
                duration: duration,
                curve: KMotion.emphasized,
                child: AnimatedDefaultTextStyle(
                  style: style,
                  duration: duration,
                  curve: KMotion.emphasized,
                  textAlign: lyricsTextAlign(widget.align),
                  child: widget.line.isGap
                      ? _Gap(
                          active: isCurrent,
                          centered: centered,
                          label: l10n.lyricsGapLabel,
                        )
                      : Text(widget.line.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap({
    required this.active,
    required this.centered,
    required this.label,
  });

  final bool active;
  final bool centered;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color ?? Colors.white;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Align(
          alignment: centered ? Alignment.center : Alignment.centerLeft,
          child: LyricsGapMark(active: active, color: color),
        ),
      ),
    );
  }
}
