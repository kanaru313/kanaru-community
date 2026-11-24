import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../media/domain/track_id.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import '../state/playing_lyrics_providers.dart';
import '../state/translation/translation_layout_provider.dart';
import '../state/translation/translation_settings.dart';
import '../state/translation/translation_providers.dart';
import 'lyrics_gap_mark.dart';
import 'lyrics_text_styles.dart';
import 'translation/line_translation.dart';
import 'translation/shown_translation.dart';
import 'translation/translation_placeholder.dart';
import 'translation/translation_text_styles.dart';

/// A blank that still takes the height of a line.
const String cardBlankLine = ' ';

/// Previous, current and next line of synced lyrics; watches the line index
/// itself so only these three rows rebuild when it changes.
class CardSyncedLines extends ConsumerWidget {
  const CardSyncedLines({
    super.key,
    required this.lyrics,
    required this.size,
    required this.dim,
    required this.textAlign,
    this.trackId,
  });

  /// The track whose translation shows under the sung line; null shows none.
  final TrackId? trackId;
  final Lyrics lyrics;
  final double size;
  final LyricsDim dim;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(playingLyricsLineProvider);
    final id = trackId;
    final layout = id == null ? null : ref.watch(translationLayoutProvider(id));
    final trSize = ref.watch(translationSizeProvider);
    final lines = lyrics.lines;
    // A gap line is the three-note mark; the slots outside the list are empty.
    LyricLine? lineAt(int i) => i < 0 || i >= lines.length ? null : lines[i];
    TextStyle style(bool strong) => lyricsLineStyle(
      context,
      size: size,
      current: strong,
      dim: dim,
    ).copyWith(height: 26 / 18);
    // Before the first line the current row is the mark, the first line next.
    final current = index < 0
        ? const LyricLine(Duration.zero, '')
        : lineAt(index);
    // A leading gap line is already the mark of the current row: no second one.
    final next = index < 0 && (lineAt(0)?.isGap ?? false)
        ? null
        : lineAt(index + 1);
    return TranslationPresence(
      trackId: id,
      active: layout != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardRow(
            line: index < 0 ? null : lineAt(index - 1),
            active: false,
            style: style(false),
            textAlign: textAlign,
          ),
          _CardRow(
            line: current,
            active: true,
            style: style(true),
            textAlign: textAlign,
          ),
          // With translation on the row is always there, so the card keeps its
          // height from line to line.
          if (id != null && layout != null)
            _CardTranslation(
              trackId: id,
              line: current,
              rtl: layout.rtl,
              style: cardTranslationStyle(context, style(true), trSize),
              textAlign: textAlign,
            ),
          _CardRow(
            line: next,
            active: false,
            style: style(false),
            textAlign: textAlign,
          ),
        ],
      ),
    );
  }
}

/// One row of the card window: text, the gap mark for a gap line (pulsing
/// only while it is the current row), or nothing for a missing line.
class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.line,
    required this.active,
    required this.style,
    required this.textAlign,
  });

  final LyricLine? line;
  final bool active;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final line = this.line;
    if (line == null) {
      return CardOneLine(
        text: cardBlankLine,
        style: style,
        textAlign: textAlign,
      );
    }
    if (!line.isGap) {
      return CardOneLine(text: line.text, style: style, textAlign: textAlign);
    }
    return SizedBox(
      height:
          MediaQuery.textScalerOf(context).scale(style.fontSize ?? 18) *
          (style.height ?? 1.4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: textAlign == TextAlign.center
            ? Alignment.center
            : Alignment.centerLeft,
        child: LyricsGapMark(
          active: active,
          color: style.color ?? Colors.white,
        ),
      ),
    );
  }
}

class CardOneLine extends StatelessWidget {
  const CardOneLine({
    super.key,
    required this.text,
    required this.style,
    required this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: style,
    textAlign: textAlign,
  );
}

/// The translation of the sung line, one line (size from the setting): the
/// text, a bar while it is coming, a blank of the same height otherwise (a
/// gap, no translation).
class _CardTranslation extends ConsumerWidget {
  const _CardTranslation({
    required this.trackId,
    required this.line,
    required this.rtl,
    required this.style,
    required this.textAlign,
  });

  final TrackId trackId;
  final LyricLine? line;
  final bool rtl;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = this.line;
    final shown = line == null
        ? (text: null, pending: false)
        : ref.watch(
            trackTranslationProvider(trackId)
                .select((v) => lineTranslationOf(line, v)),
          );
    final text = shown.text;
    if (text == null && shown.pending) {
      return TranslationPlaceholder(
        style: style,
        centered: textAlign == TextAlign.center,
      );
    }
    return Text(
      text ?? cardBlankLine,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
      textAlign: textAlign,
      textDirection: text != null && rtl ? TextDirection.rtl : null,
    );
  }
}
