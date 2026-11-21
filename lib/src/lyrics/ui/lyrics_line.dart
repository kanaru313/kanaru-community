import 'package:flutter/foundation.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import 'lyrics_gap_dots.dart';
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

/// One line of synced lyrics. Rebuilds only when [current] flips, never on a
/// position tick; pressing it seeks to the line. A timed blank line is a gap
/// (three dots). Its own repaint boundary keeps a scroll past it, or a
/// neighbour changing style, from laying the text out again.
class LyricsLine extends StatelessWidget {
  const LyricsLine({
    super.key,
    required this.line,
    required this.current,
    required this.onTap,
    required this.size,
    required this.dim,
    required this.align,
  });

  final LyricLine line;
  final ValueListenable<bool> current;
  final VoidCallback onTap;
  final double size;
  final LyricsDim dim;
  final LyricsAlign align;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.slow;
    final centered = align == LyricsAlign.center;
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x1),
      child: RepaintBoundary(
        child: ValueListenableBuilder<bool>(
          valueListenable: current,
          builder: (context, isCurrent, _) {
            final style = lyricsLineStyle(
              context,
              size: size,
              current: isCurrent,
              dim: dim,
            );
            return Semantics(
              button: true,
              selected: isCurrent,
              onTapHint: l10n.lyricsSeekHint(lyricsClock(line.time)),
              child: InkWell(
                onTap: onTap,
                borderRadius: KRadius.md,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: lyricsLineInset,
                    vertical: KSpace.x2,
                  ),
                  child: AnimatedScale(
                    scale: isCurrent ? _currentScale : 1,
                    alignment: centered
                        ? Alignment.center
                        : Alignment.centerLeft,
                    duration: duration,
                    curve: KMotion.emphasized,
                    child: AnimatedDefaultTextStyle(
                      style: style,
                      duration: duration,
                      curve: KMotion.emphasized,
                      textAlign: lyricsTextAlign(align),
                      child: line.isGap
                          ? _Gap(
                              active: isCurrent,
                              centered: centered,
                              label: l10n.lyricsGapLabel,
                            )
                          : Text(line.text),
                    ),
                  ),
                ),
              ),
            );
          },
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
          child: LyricsGapDots(active: active, color: color),
        ),
      ),
    );
  }
}
