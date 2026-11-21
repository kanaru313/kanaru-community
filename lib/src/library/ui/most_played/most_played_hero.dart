import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/history_ranges.dart';
import '../../domain/playlists/playlist_cover_rule.dart';
import '../browse/play_shuffle_buttons.dart';
import '../menus/more_button.dart';
import '../playlist_common/auto_cover_art.dart';
import '../playlist_common/playlist_cover.dart' show playlistCoverFileSize;
import 'most_played_labels.dart';
import 'most_played_menus.dart';

/// Cover keys of the hero's automatic cover: the distinct albums of the top
/// ranks, best first (at most four; songs whose file is gone are skipped),
/// picked by the playlist rule.
List<String> mostPlayedCoverKeys(List<TopEntry> entries) => pickAutoCoverKeys(
  entries.where((e) => canPlayTrack(e.track)).map((e) {
    final album = e.track.albumKey;
    return (
      group: album == null
          ? 't${e.track.id.value}'
          : '${album.artistKey}|${album.titleKey}',
      coverKey: e.track.coverKey,
    );
  }),
);

/// Top of the Most played page: the framed cover (a mosaic of the top
/// albums), "Phát nhiều nhất", the period's dates (`16/10 – 14/11/2026`; the chosen chip names the preset, and the
/// one-line detail line has no room for both on a phone),
/// `M bài · N lượt nghe` and `[▶ Phát] [shuffle] [⋮]`.
///
/// Play, shuffle and ⋮ wait while the list reloads ([stale]) and are off for
/// a list with nothing to play.
class MostPlayedHero extends StatelessWidget {
  const MostPlayedHero({
    super.key,
    required this.data,
    required this.range,
    required this.today,
    required this.stale,
    required this.coverKeys,
    this.showTotals = true,
  });

  final MostPlayed data;
  final MostPlayedRange range;
  final DateTime today;
  final bool stale;
  final List<String> coverKeys;

  /// False after a failed read: there are no totals to state.
  final bool showTotals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = !stale && data.entries.any((e) => canPlayTrack(e.track));
    return KDetailHero(
      framedCover: true,
      coverBuilder: (context, side, radius) => ExcludeSemantics(
        child: autoCoverArt(
          keys: coverKeys,
          seed: 'most-played',
          size: playlistCoverFileSize(
            coverKeys.length > 1 ? side / 2 : side,
            MediaQuery.devicePixelRatioOf(context),
          ),
          dimension: side,
          radius: radius,
        ),
      ),
      title: l10n.libraryNavMostPlayed,
      line2: KDetailLine(text: mostPlayedPeriodText(l10n, range, today)),
      line3: showTotals
          ? l10n.historyMostPlayedHeroTotals(data.songs, data.plays)
          : null,
      actions: PlayShuffleButtons(
        compact: false,
        labelled: true,
        playLabel: l10n.libraryPlay,
        onPlay: enabled
            ? () => unawaited(playMostPlayedOrToast(context, data.entries))
            : null,
        onShuffle: enabled
            ? () => unawaited(
                playMostPlayedOrToast(context, data.entries, shuffle: true),
              )
            : null,
        trailing: [
          LibraryMoreButton(
            large: true,
            onPressed: ({required viaKeyboard}) => unawaited(
              openMostPlayedMenu(
                context,
                data: data,
                range: range,
                today: today,
                stale: stale,
                viaKeyboard: viaKeyboard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
