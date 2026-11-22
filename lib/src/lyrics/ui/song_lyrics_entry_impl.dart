import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../database/app_database.dart';
import '../../library/ui/menus/song_lyrics_entry.dart';
import '../../media/domain/track_id.dart';
import '../data/lyrics_facts_query.dart';
import '../domain/local_lyrics_pick.dart';
import '../domain/lyrics_summary.dart';
import '../state/lyrics_loader_provider.dart';
import '../state/lyrics_settings.dart';
import 'lyrics_for_track_modal.dart';
import 'lyrics_labels.dart';

/// The song menu's "Lyrics source" row: one database read of the song's
/// choice, then the loader's memory cache. A song not read this session has
/// no subtitle (the file is never read for a menu).
class LyricsSongEntry implements SongLyricsEntry {
  const LyricsSongEntry();

  @override
  Future<String?> label(
    AppDatabase db,
    ProviderContainer container,
    TrackId id,
    AppLocalizations l10n,
  ) async {
    final facts = await watchLyricsFacts(db, id).first;
    if (facts != null && facts.off) {
      return lyricsSummaryLabel(l10n, LyricsSummary.off);
    }
    final read = container.read(lyricsLoaderProvider).peek(id);
    if (read == null) return null;
    final pick = pickLocalLyrics(
      tag: read.tag,
      lrc: read.lrc,
      first: container.read(lyricsLocalFirstProvider),
    );
    final shown = pick.shown;
    final summary = read.unavailable != null || shown == null
        ? LyricsSummary.none
        : summaryOfLyrics(shown);
    return lyricsSummaryLabel(l10n, summary);
  }

  @override
  Future<void> open(BuildContext context, TrackId id) =>
      showLyricsForTrack(context, id, followsPlaying: false);
}
