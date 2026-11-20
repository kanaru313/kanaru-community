import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/track_lines.dart';
import '../../../../playback/ui/track_cover.dart';
import '../../../domain/history/history_models.dart';
import '../../../state/browse/detail_expand_providers.dart';
import '../../../state/history/history_actions.dart';
import '../../browse/library_labels.dart';
import '../../playlist_common/playlist_cover.dart' show playlistCoverFileSize;
import 'track_history_labels.dart';

/// Top of the page of one song's plays: its cover, title, artist, `N plays`,
/// a single `[▶ Play]` and the summary of its plays.
///
/// A song whose file is gone shows dimmed, with Play disabled and the reason
/// as its tooltip.
class TrackHistoryHero extends ConsumerStatefulWidget {
  const TrackHistoryHero({
    super.key,
    required this.history,
    required this.today,
  });

  final TrackHistory history;

  /// The local day the page is on.
  final DateTime today;

  @override
  ConsumerState<TrackHistoryHero> createState() => _TrackHistoryHeroState();
}

class _TrackHistoryHeroState extends ConsumerState<TrackHistoryHero> {
  /// A Play press is being served: further presses are ignored.
  bool _serving = false;

  Future<void> _play() async {
    if (_serving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final track = widget.history.track;
    setState(() => _serving = true);
    try {
      final ok = await ref
          .read(historyActionsProvider)
          .playFrom([track], track, label: l10n.historyTitle);
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
    final history = widget.history;
    final track = history.track;
    final missing = !canPlayTrack(track);
    final artist = trackArtistLine(track);
    final summary = trackHistorySummary(
      l10n,
      history,
      widget.today,
      formatTotal: (ms) => formatTotalDuration(l10n, ms),
    );
    final pageKey = 'history-track:${track.id.value}';
    final expanded = ref.watch(
      detailDescriptionExpandedProvider.select((s) => s.contains(pageKey)),
    );
    final play = FilledButton.icon(
      onPressed: missing || _serving ? null : () => unawaited(_play()),
      icon: const Icon(KIcons.play),
      label: Text(l10n.libraryPlay),
    );
    return Opacity(
      opacity: missing ? 0.5 : 1,
      child: KDetailHero(
        coverBuilder: (context, side, radius) => ExcludeSemantics(
          child: TrackCover(
            coverKey: track.coverKey,
            seed: track.coverSeed,
            size: playlistCoverFileSize(
              side,
              MediaQuery.devicePixelRatioOf(context),
            ),
            dimension: side,
            radius: radius,
          ),
        ),
        title: track.title,
        line2: artist.isEmpty ? null : KDetailLine(text: artist),
        line3: l10n.historyHeroPlays(history.plays),
        actions: missing
            ? Tooltip(message: l10n.historyMissingTap, child: play)
            : play,
        description: summary == null
            ? null
            : KDetailDescription(
                text: summary,
                expanded: expanded,
                onExpandedChanged: (v) => ref
                    .read(detailDescriptionExpandedProvider.notifier)
                    .set(pageKey, v),
                moreLabel: l10n.libraryShowMore,
                lessLabel: l10n.libraryShowLess,
              ),
      ),
    );
  }
}
