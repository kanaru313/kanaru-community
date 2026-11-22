import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../domain/lyrics_status.dart';
import '../domain/lyrics_summary.dart';
import '../state/lyrics_choice_commands.dart';
import '../state/track_lyrics_providers.dart';

final _log = Logger('lyrics_choice_rows');

/// The lyrics a track's file holds, whatever the user chose: what the
/// "Lời trong file" row describes. Null when the file has none or the read
/// has not finished.
LyricsSummary? fileLyricsSummary(TrackLyrics lyrics) => switch (lyrics) {
  LyricsShown(:final lyrics) => summaryOfLyrics(lyrics),
  LyricsOff(:final available?) => summaryOfLyrics(available),
  _ => null,
};

/// The two single-choice rows of "Lời cho bài này": lyrics from the file and
/// no lyrics. The chosen row is shown by its tint and bold title only.
///
/// Choosing reads the commands, closes the modal through [close], then writes
/// one choice. The row that is already chosen only closes. [close] returns
/// false when the modal is already closing: nothing is written then, so a
/// double tap writes once.
class LyricsChoiceRows extends ConsumerWidget {
  const LyricsChoiceRows({
    super.key,
    required this.trackId,
    required this.close,
  });

  final TrackId trackId;
  final bool Function() close;

  void _choose(WidgetRef ref, {required bool off, required bool chosen}) {
    final commands = ref.read(lyricsChoiceCommandsProvider);
    if (!close() || chosen) return;
    final write = off ? commands.setOff(trackId) : commands.clear(trackId);
    unawaited(
      write.catchError((Object error, StackTrace stack) {
        _log.warning('lyrics choice write failed', error, stack);
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lyrics = ref.watch(trackLyricsProvider(trackId));
    final fileSummary = fileLyricsSummary(lyrics);
    final isOff = lyrics is LyricsOff;
    final fileChosen = lyrics is LyricsShown;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectionRow(
          leading: const Icon(KIcons.musicFile),
          title: Text(l10n.lyricsChoiceFile),
          subtitle: Text(
            fileSummary == null
                ? l10n.lyricsChoiceFileNone
                : _fileSubtitle(l10n, fileSummary),
          ),
          selected: fileChosen,
          enabled: fileSummary != null,
          onTap: () => _choose(ref, off: false, chosen: fileChosen),
        ),
        SelectionRow(
          leading: const Icon(KIcons.lyricsOff),
          title: Text(l10n.lyricsChoiceOff),
          selected: isOff,
          onTap: () => _choose(ref, off: true, chosen: isOff),
        ),
      ],
    );
  }
}

String _fileSubtitle(AppLocalizations l10n, LyricsSummary summary) =>
    switch (summary) {
      LyricsSummary.tagSynced => l10n.lyricsChoiceSubTagSynced,
      LyricsSummary.tagPlain => l10n.lyricsChoiceSubTagPlain,
      LyricsSummary.lrcSynced => l10n.lyricsChoiceSubLrcSynced,
      LyricsSummary.lrcPlain => l10n.lyricsChoiceSubLrcPlain,
      _ => l10n.lyricsChoiceFileNone,
    };
