import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/ui/track_cover.dart';
import '../../domain/history/history_models.dart';
import '../../state/history/history_actions.dart';
import '../browse/play_shuffle_buttons.dart';
import '../playlist_common/playlist_cover.dart' show playlistCoverFileSize;
import 'history_labels.dart';
import 'history_menus.dart';

/// Covers of the four most recent distinct albums among [plays] (newest
/// first); fewer than four give an empty list, and the hero shows one cover.
List<TrackInfo> historyMosaicTracks(List<HistoryPlay> plays) {
  final seen = <String>{};
  final out = <TrackInfo>[];
  for (final p in plays) {
    final key = p.track.coverKey;
    if (key == null || !seen.add(key)) continue;
    out.add(p.track);
    if (out.length == 4) return out;
  }
  return const [];
}

/// Top of the History page: the cover (a 2 x 2 mosaic of the latest albums,
/// else one cover), "History", `N plays`, `M songs · since dd/mm/yyyy`, and
/// `[▶ Play all] [shuffle] [⋮]`. [plays] is the newest year's read and may
/// still be null: the hero shows from the overview alone.
class HistoryHero extends ConsumerStatefulWidget {
  const HistoryHero({super.key, required this.overview, required this.plays});

  final HistoryOverview overview;
  final List<HistoryPlay>? plays;

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
    final plays = widget.plays ?? const <HistoryPlay>[];
    final mosaic = historyMosaicTracks(plays);
    final enabled = overview.plays > 0 && !_serving;
    return KDetailHero(
      coverBuilder: (context, side, radius) => _HistoryCover(
        mosaic: mosaic,
        single: plays.firstOrNull?.track,
        dimension: side,
        radius: radius,
      ),
      title: l10n.historyTitle,
      line2: KDetailLine(text: l10n.historyHeroPlays(overview.plays)),
      line3: since == null
          ? null
          : l10n.historyHeroSongsSince(overview.songs, historyDate(since)),
      actions: PlayShuffleButtons(
        compact: false,
        labelled: true,
        playLabel: l10n.libraryPlayAll,
        onPlay: enabled ? () => unawaited(_play(shuffle: false)) : null,
        onShuffle: enabled ? () => unawaited(_play(shuffle: true)) : null,
        trailing: [
          KIconButton(
            tooltip: l10n.libraryMenuMore,
            size: KIconSize.md,
            padding: const EdgeInsets.all(KSpace.x3),
            onPressed: () => unawaited(openHistoryPageMenu(context)),
            icon: KIcons.moreVert,
          ),
        ],
      ),
    );
  }
}

class _HistoryCover extends StatelessWidget {
  const _HistoryCover({
    required this.mosaic,
    required this.single,
    required this.dimension,
    required this.radius,
  });

  final List<TrackInfo> mosaic;
  final TrackInfo? single;
  final double dimension;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget one(TrackInfo? t, double side, BorderRadius r) => TrackCover(
      coverKey: t?.coverKey,
      seed: t?.coverSeed ?? 'history',
      size: playlistCoverFileSize(side, dpr),
      dimension: side,
      radius: r,
    );
    final cover = mosaic.length == 4
        ? KCoverMosaic(
            size: dimension,
            radius: radius,
            tiles: [
              for (final t in mosaic)
                (context, w, h) => ClipRect(
                  child: OverflowBox(
                    minWidth: math.max(w, h),
                    maxWidth: math.max(w, h),
                    minHeight: math.max(w, h),
                    maxHeight: math.max(w, h),
                    child: one(t, math.max(w, h), BorderRadius.zero),
                  ),
                ),
            ],
          )
        : one(single, dimension, radius);
    return ExcludeSemantics(child: cover);
  }
}
