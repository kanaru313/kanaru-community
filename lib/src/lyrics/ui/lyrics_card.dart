import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics_status.dart';
import '../state/lyrics_settings.dart';
import '../state/playing_lyrics_providers.dart';
import 'lyrics_labels.dart';
import 'online/online_labels.dart';
import 'online/online_source_of.dart';
import 'online/plugin_avatar.dart';
import 'lyrics_card_lines.dart';
import 'lyrics_text_styles.dart';
import 'lyrics_spinner.dart';

/// Widest the source (icon and name) may grow in the header; the title
/// keeps the rest, so the open icon always ends at the right edge.
const double _sourceMaxWidth = 160;

/// A blank that still takes the height of a line.
const String cardBlankLine = ' ';

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
    final source = lyricsLabelOf(l10n, playing, short: true);
    final online = onlineShownOf(playing);
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                    ),
                    // The source (plugin icon and name, or the short label)
                    // sits against the open icon; a long name ellipsizes.
                    if (online != null || source.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: _sourceMaxWidth),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: KSpace.x2,
                          children: [
                            if (online != null)
                              PluginAvatar(
                                providerId: online.providerId,
                                name: online.providerName,
                                size: KIconSize.xs,
                              ),
                            if (source.isNotEmpty)
                              Flexible(
                                child: Text(
                                  source,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
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
        return CardSyncedLines(
          trackId: ref.watch(playingLyricsProvider.select((p) => p.trackId)),
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
              CardOneLine(text: line.text, style: style, textAlign: textAlign),
          ],
        );
      case LyricsNone() || LyricsUnavailable() || LyricsNoSource():
        status = l10n.lyricsCardNone;
      case LyricsNotFound():
        status = l10n.lyricsNotFoundTitle;
      case LyricsInstrumental():
        status = l10n.lyricsInstrumentalTitle;
      case LyricsLookupFailed(:final retryAt):
        status = retryAt == null
            ? l10n.lyricsFailedTitle
            : l10n.lyricsCardFailedRetry(formatClock(context, retryAt));
      case LyricsLookupPaused(:final until):
        status = l10n.lyricsCardPaused(formatClock(context, until));
      case LyricsOff():
        status = l10n.lyricsCardOff;
      case LyricsSearching():
        return _SearchingLine(text: l10n.lyricsSearchingTitle);
      case LyricsLoading():
        status = cardBlankLine;
    }
    return Text(
      status,
      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

/// "Đang tìm lời…" with a small spinner (a still arc with animations off).
class _SearchingLine extends StatelessWidget {
  const _SearchingLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      spacing: KSpace.x2,
      children: [
        LyricsSpinner(
          size: KIconSize.xs,
          color: scheme.onSurfaceVariant,
          label: AppLocalizations.of(context).lyricsSearchingTitle,
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
