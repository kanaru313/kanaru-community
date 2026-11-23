import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import '../domain/lyrics_status.dart';
import '../domain/lyrics_summary.dart';
import '../state/lyrics_settings.dart';
import '../state/playing_lyrics_providers.dart';
import 'lyrics_labels.dart';
import 'lyrics_gap_mark.dart';
import 'lyrics_text_styles.dart';

/// A blank that still takes the height of a line.
const String _blank = ' ';

/// The lyrics card of the mobile Now Playing page: title, the source and an
/// open icon on top, then three lines that follow the song (the one before
/// and after dimmed, the current one strong), the first three lines of plain
/// lyrics, or one status line. The whole card is one button that calls
/// [onOpen] (null leaves it inert).
class LyricsCard extends ConsumerWidget {
  const LyricsCard({super.key, required this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final playing = ref.watch(playingLyricsProvider).lyrics;
    final source = lyricsSummaryLabel(l10n, summaryOf(playing), short: true);
    final label = source.isEmpty
        ? l10n.playbackLyricsCard
        : l10n.lyricsCardLabel(l10n.playbackLyricsCard, source);
    return Semantics(
      container: true,
      button: true,
      enabled: onOpen != null,
      label: label,
      onTapHint: l10n.lyricsCardOpenHint,
      excludeSemantics: true,
      onTap: onOpen,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: KRadius.lg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(KSpace.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: KSpace.x2,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.playbackLyricsCard,
                        style: text.titleSmall,
                      ),
                    ),
                    if (source.isNotEmpty)
                      Text(
                        source,
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    Icon(
                      KIcons.openFull,
                      size: KIconSize.sm,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: KSpace.x2),
                _CardBody(lyrics: playing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBody extends ConsumerWidget {
  const _CardBody({required this.lyrics});

  final TrackLyrics lyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fontScale = ref.watch(lyricsFontScaleProvider).factor;
    final align = ref.watch(lyricsAlignProvider);
    final dim = ref.watch(lyricsDimProvider);
    final textAlign = lyricsTextAlign(align);
    String? status;
    switch (lyrics) {
      case LyricsShown(:final lyrics) when lyrics.synced:
        return _SyncedLines(
          lyrics: lyrics,
          size: KLyricsMetrics.cardLineSize * fontScale,
          dim: dim,
          textAlign: textAlign,
        );
      case LyricsShown(:final lyrics):
        final style = lyricsPlainStyle(
          context,
          size: KLyricsMetrics.cardPlainLineSize * fontScale,
        ).copyWith(fontWeight: FontWeight.w500, height: 22 / 15);
        final first = lyrics.lines
            .where((line) => line.text.isNotEmpty)
            .take(3)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in first)
              _OneLine(text: line.text, style: style, textAlign: textAlign),
          ],
        );
      case LyricsNone() ||
          LyricsUnavailable() ||
          LyricsNotFound() ||
          LyricsNoSource() ||
          LyricsInstrumental() ||
          LyricsLookupFailed() ||
          LyricsLookupPaused():
        status = l10n.lyricsCardNone;
      case LyricsOff():
        status = l10n.lyricsCardOff;
      case LyricsLoading() || LyricsSearching():
        status = _blank;
    }
    return Text(
      status,
      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

/// Previous, current and next line of synced lyrics; watches the line index
/// itself so only these three rows rebuild when it changes.
class _SyncedLines extends ConsumerWidget {
  const _SyncedLines({
    required this.lyrics,
    required this.size,
    required this.dim,
    required this.textAlign,
  });

  final Lyrics lyrics;
  final double size;
  final LyricsDim dim;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(playingLyricsLineProvider);
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
    return Column(
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
        _CardRow(
          line: next,
          active: false,
          style: style(false),
          textAlign: textAlign,
        ),
      ],
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
      return _OneLine(text: _blank, style: style, textAlign: textAlign);
    }
    if (!line.isGap) {
      return _OneLine(text: line.text, style: style, textAlign: textAlign);
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

class _OneLine extends StatelessWidget {
  const _OneLine({
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
