/// Lyrics text size (setting `lyrics.font_scale`).
enum LyricsFontScale {
  small(0.85),
  medium(1.0),
  large(1.2);

  const LyricsFontScale(this.factor);

  /// Multiplier on the base size of the shell.
  final double factor;
}

/// Alignment of the lyrics lines (setting `lyrics.align`).
enum LyricsAlign { start, center }

/// Seconds without touch before the view returns to the current line
/// (setting `lyrics.auto_return`).
enum LyricsAutoReturn {
  off(null),
  s3(Duration(seconds: 3)),
  s5(Duration(seconds: 5)),
  s10(Duration(seconds: 10));

  const LyricsAutoReturn(this.delay);

  /// Null = never returns by itself.
  final Duration? delay;
}

/// How much the lines that are not being sung are dimmed (setting
/// `lyrics.dim`).
enum LyricsDim {
  light(0.36),
  strong(0.20),
  off(1.0);

  const LyricsDim(this.alpha);

  /// Alpha of `onSurface` for the other lines.
  final double alpha;
}
