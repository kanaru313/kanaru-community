import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../domain/lyrics_status.dart';
import '../domain/lyrics_summary.dart';
import '../domain/online/online_lyrics_ref.dart';
import '../state/lyrics_choice_commands.dart';
import '../state/track_lyrics_providers.dart';
import 'online/online_labels.dart';
import 'online/online_row_info.dart';
import 'online/online_source_providers.dart';
import 'online/plugin_avatar.dart';

final _log = Logger('lyrics_choice_rows');

/// The lyrics a track's file holds, whatever the user chose: what the
/// "Lời trong file" row describes. Null when the file has none or the read
/// has not finished.
LyricsSummary? fileLyricsSummary(TrackLyrics lyrics) => switch (lyrics) {
  LyricsShown(:final lyrics) when lyrics.online == null => summaryOfLyrics(
    lyrics,
  ),
  LyricsOff(:final available?) when available.online == null => summaryOfLyrics(
    available,
  ),
  _ => null,
};

/// The single-choice rows of "Lời cho bài này": lyrics from the file, the
/// online copy (only when the track has one: shown, kept, or what automatic
/// selection would show) and no lyrics. The chosen row is shown by its tint
/// and bold title only.
///
/// Choosing reads the commands, closes the modal through [close], then writes
/// one choice. The row that is already chosen only closes. [close] returns
/// false when the modal is already closing: nothing is written then, so a
/// double tap writes once. "Lời trong file" while a kept copy exists is a
/// choice of its own (the file wins, the kept copy stays and its row stays);
/// without one it is plain automatic selection.
class LyricsChoiceRows extends ConsumerWidget {
  const LyricsChoiceRows({
    super.key,
    required this.trackId,
    required this.close,
    this.online,
  });

  final TrackId trackId;
  final bool Function() close;

  /// The online row's data, from [onlineRowInfoOf]; null hides the row.
  final OnlineRowInfo? online;

  void _choose(
    WidgetRef ref,
    Future<void> Function(LyricsChoiceCommands commands) write, {
    required bool chosen,
  }) {
    final commands = ref.read(lyricsChoiceCommandsProvider);
    if (!close() || chosen) return;
    unawaited(
      write(commands).catchError((Object error, StackTrace stack) {
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
    final fileChosen = lyrics is LyricsShown && lyrics.lyrics.online == null;
    final online = this.online;
    final keptCopy = online != null && online.how == OnlineHow.kept;
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
          onTap: () => _choose(
            ref,
            (c) => keptCopy ? c.setFile(trackId) : c.clear(trackId),
            chosen: fileChosen,
          ),
        ),
        if (online != null)
          SelectionRow(
            leading: PluginAvatar(
              providerId: online.providerId,
              name: online.providerName,
              size: KIconSize.md,
            ),
            title: Text(l10n.lyricsChoiceOnline),
            subtitle: Text(
              onlineRowSubtitle(
                l10n,
                online,
                removed: ref.watch(
                  onlineSourceRemovedProvider(online.providerId),
                ),
              ),
            ),
            selected: online.selected,
            onTap: () =>
                _choose(ref, (c) => c.clear(trackId), chosen: online.selected),
          ),
        SelectionRow(
          leading: const Icon(KIcons.lyricsOff),
          title: Text(l10n.lyricsChoiceOff),
          selected: isOff,
          onTap: () => _choose(ref, (c) => c.setOff(trackId), chosen: isOff),
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
