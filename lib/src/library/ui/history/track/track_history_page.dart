import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/track_id.dart';
import '../../../state/history/history_providers.dart';
import '../../../state/history/local_day_provider.dart';
import '../../playlists/page/playlist_page_states.dart'
    show PlaylistStateSliver;
import '../history_page_frame.dart';
import 'track_history_hero.dart';
import 'track_history_rows.dart';

final _log = Logger('library.history');

/// Plays of one song, opened from the History row menu: the song as the hero
/// and every play newest first.
///
/// A [trackId] that is null (the path had none) or names no song shows the
/// empty line alone. When every play is removed the hero stays and the line
/// takes the list's place.
class TrackHistoryPage extends ConsumerWidget {
  const TrackHistoryPage({super.key, required this.trackId});

  final int? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = trackId;
    if (id == null) return _empty(l10n);
    final async = ref.watch(trackHistoryProvider(TrackId(id)));
    // A reload that fails keeps the rows on screen and says so.
    ref.listen(trackHistoryProvider(TrackId(id)), (prev, next) {
      if (next is! AsyncError || !next.hasValue) return;
      _log.warning(
        'Reloading a song history failed: ${next.error.runtimeType}',
      );
      showAppSnackBar(context, l10n.libraryLoadFailed);
    });
    // A reload after a change keeps the last answer on screen.
    if (!async.hasValue) {
      return HistoryPageFrame(
        title: '',
        titleInContent: true,
        showBack: true,
        child: async.hasError
            ? Center(
                child: Text(
                  l10n.libraryLoadFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            : const SizedBox.shrink(),
      );
    }
    final history = async.requireValue;
    if (history == null) return _empty(l10n);
    final today = ref.watch(localDayProvider);
    return HistoryPageFrame.layout(
      title: history.track.title,
      showBack: true,
      header: TrackHistoryHero(history: history, today: today),
      slivers: [
        if (history.list.isEmpty)
          PlaylistStateSliver(
            child: KEmpty(
              icon: KIcons.history,
              message: l10n.historyTrackEmpty,
            ),
          )
        else
          trackHistoryRows(history.list, today),
      ],
    );
  }

  Widget _empty(AppLocalizations l10n) => HistoryPageFrame(
    title: '',
    showBack: true,
    child: KEmpty(icon: KIcons.history, message: l10n.historyTrackEmpty),
  );
}
