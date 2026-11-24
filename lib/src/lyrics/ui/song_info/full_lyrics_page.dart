import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/lyrics.dart';
import 'full_lyrics_data.dart';
import 'full_lyrics_lines.dart';
import 'lyrics_kind_pill.dart';
import 'song_info_lyrics_labels.dart';
import 'song_info_lyrics_prefs.dart';

/// Opens the "Lời bài hát" modal over the song info page: a 560 box on tablet
/// and desktop, a full page on a phone. Back, Esc and ✕ close only this
/// layer. The header has the timestamps toggle, then "Chép lời".
Future<void> showFullLyrics(BuildContext context, FullLyricsData data) {
  final l10n = AppLocalizations.of(context);
  return showKOverlayPage<void>(
    context,
    title: l10n.lyricsInfoGroup,
    subtitle: data.songTitle.isEmpty ? null : data.songTitle,
    maxWidth: 560,
    boxHeader: (_) => _BoxHeader(song: data.song),
    actions: [
      _StampsButton(synced: data.lyrics.synced),
      _CopyButton(lyrics: data.lyrics),
    ],
    builder: (_) => _Body(data: data),
  );
}

class _BoxHeader extends StatelessWidget {
  const _BoxHeader({required this.song});

  final String song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).lyricsInfoGroup,
          style: theme.textTheme.headlineSmall,
        ),
        if (song.isNotEmpty)
          Text(
            song,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// The clock toggle: on shows the `m:ss` column. Plain lyrics have no times,
/// so it is disabled and says why.
class _StampsButton extends ConsumerWidget {
  const _StampsButton({required this.synced});

  final bool synced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(lyricsInfoShowTimestampsProvider);
    return KInfoToggleButton(
      on: synced && on,
      onChanged: synced
          ? (v) => ref.read(lyricsInfoShowTimestampsProvider.notifier).set(v)
          : null,
      icon: KIcons.timestamps,
      onIcon: KIcons.timestamps,
      tooltip: l10n.lyricsInfoShowStamps,
      onTooltip: l10n.lyricsInfoHideStamps,
      disabledTooltip: l10n.lyricsPickerPlainNote,
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.lyrics});

  final Lyrics lyrics;

  Future<void> _copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: lyricsCopyText(lyrics)));
    } on PlatformException catch (error, stack) {
      // The clipboard refused: report it, and no "copied" message.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'lyrics',
          context: ErrorDescription('copying the lyrics'),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      l10n.lyricsInfoCopied(lyricsTextLineCount(lyrics)),
    );
  }

  @override
  Widget build(BuildContext context) => KIconButton(
    tooltip: AppLocalizations.of(context).lyricsInfoCopy,
    icon: KIcons.copy,
    onPressed: () => _copy(context),
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final FullLyricsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final lyrics = data.lyrics;
    final stamps = lyrics.synced && ref.watch(lyricsInfoShowTimestampsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x6,
            KSpace.x3,
            KSpace.x6,
            KSpace.x2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: KSpace.x2,
                children: [
                  LyricsKindPill(synced: lyrics.synced),
                  Expanded(
                    child: Text(
                      '${data.source} · '
                      '${l10n.lyricsInfoLines(lyricsTextLineCount(lyrics))}',
                      style: muted,
                    ),
                  ),
                ],
              ),
              if (!lyrics.synced)
                Padding(
                  padding: const EdgeInsets.only(top: KSpace.x2),
                  child: Row(
                    spacing: KSpace.x2,
                    children: [
                      Icon(
                        KIcons.info,
                        size: KIconSize.xs,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: Text(l10n.lyricsPickerPlainNote, style: muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FullLyricsLines(
            lyrics: lyrics,
            stamps: stamps,
            selectable: FormFactor.of(context) == FormFactor.desktop,
          ),
        ),
      ],
    );
  }
}
