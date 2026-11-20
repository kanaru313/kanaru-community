import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../../domain/playlists/playlist_cover_rule.dart';
import '../../state/history/history_actions.dart';
import '../browse/play_shuffle_buttons.dart';
import '../menus/more_button.dart';
import '../playlist_common/auto_cover_art.dart';
import '../playlist_common/playlist_cover.dart' show playlistCoverFileSize;
import 'history_labels.dart';
import 'history_menus.dart';

/// Cover keys of the hero's automatic cover: the most recent distinct albums
/// among [plays] (newest first, at most four; songs whose file is gone are
/// skipped), picked by the playlist rule. One key shows one cover, 2 to 4 a
/// mosaic, none a placeholder.
List<String> historyCoverKeys(List<HistoryPlay> plays) => pickAutoCoverKeys(
  plays.where((p) => canPlayTrack(p.track)).map((p) {
    final album = p.track.albumKey;
    return (
      group: album == null
          ? 't${p.track.id.value}'
          : '${album.artistKey}|${album.titleKey}',
      coverKey: p.track.coverKey,
    );
  }),
);

/// Top of the History page: the framed cover (a mosaic of the latest albums,
/// as a playlist's automatic cover), "History", `N plays`,
/// `M songs · since dd/mm/yyyy`, and `[▶ Play] [shuffle] [⋮]`. The hero shows
/// from the overview alone: [coverKeys] is empty until the newest year is read.
class HistoryHero extends ConsumerStatefulWidget {
  const HistoryHero({
    super.key,
    required this.overview,
    required this.coverKeys,
  });

  final HistoryOverview overview;

  /// Keys of the cover ([historyCoverKeys] of the newest year); empty until
  /// that year is read.
  final List<String> coverKeys;

  @override
  ConsumerState<HistoryHero> createState() => _HistoryHeroState();
}

class _HistoryHeroState extends ConsumerState<HistoryHero> {
  /// A Play or shuffle press is being served: further presses are ignored.
  bool _serving = false;

  Future<void> _play({required bool shuffle}) async {
    if (_serving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _serving = true);
    try {
      final ok = await ref
          .read(historyActionsProvider)
          .playAllHistory(shuffle: shuffle, label: l10n.historyTitle);
      if (!ok && messenger.mounted) {
        showAppSnackBarOn(messenger, l10n.historyPlayFailed);
      }
    } finally {
      if (mounted) setState(() => _serving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overview = widget.overview;
    final since = overview.since;
    final keys = widget.coverKeys;
    final enabled = overview.plays > 0 && !_serving;
    return KDetailHero(
      framedCover: true,
      coverBuilder: (context, side, radius) => ExcludeSemantics(
        child: autoCoverArt(
          keys: keys,
          seed: 'history',
          size: playlistCoverFileSize(
            keys.length > 1 ? side / 2 : side,
            MediaQuery.devicePixelRatioOf(context),
          ),
          dimension: side,
          radius: radius,
        ),
      ),
      title: l10n.historyTitle,
      line2: KDetailLine(text: l10n.historyHeroPlays(overview.plays)),
      line3: since == null
          ? null
          : l10n.historyHeroSongsSince(overview.songs, historyDate(since)),
      actions: PlayShuffleButtons(
        compact: false,
        labelled: true,
        playLabel: l10n.libraryPlay,
        onPlay: enabled ? () => unawaited(_play(shuffle: false)) : null,
        onShuffle: enabled ? () => unawaited(_play(shuffle: true)) : null,
        trailing: [
          LibraryMoreButton(
            large: true,
            onPressed: ({required viaKeyboard}) => unawaited(
              openHistoryPageMenu(context, viaKeyboard: viaKeyboard),
            ),
          ),
        ],
      ),
    );
  }
}
