import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../database/app_database.dart';
import '../../database/tables.dart' show LyricsPinRow;
import '../../library/ui/menus/song_lyrics_entry.dart';
import '../../media/domain/track_id.dart';
import '../data/lyrics_facts_query.dart';
import '../data/online/pin_store.dart';
import '../domain/local_lyrics_pick.dart';
import '../domain/lyrics_summary.dart';
import '../state/lyrics_loader_provider.dart';
import '../state/playing_lyrics_providers.dart';
import '../state/lyrics_settings.dart';
import 'lyrics_for_track_modal.dart';
import 'lyrics_labels.dart';
import 'online/online_labels.dart';
import 'online/online_source_of.dart';

/// The song menu's "Lyrics source" row: one database read of the song's
/// choice and kept online copy, then the loader's memory cache. A song not
/// read this session has no subtitle (the file is never read for a menu).
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
    // A kept online copy shows unless the user chose the file's lyrics.
    if (facts == null || !facts.file) {
      final pin = await PinStore(db).read(id);
      if (pin != null) return _pinLabel(l10n, pin);
    }
    // The playing song may show online lyrics found automatically.
    final playing = container.read(playingLyricsProvider);
    final online = playing.trackId == id ? onlineShownOf(playing.lyrics) : null;
    if (online != null) {
      return onlineSourceLabel(
        l10n,
        plugin: online.providerName,
        synced: online.synced,
        instrumental: online.instrumental,
      );
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

  /// "NetEase · Đồng bộ" for the kept copy of the song; the kind is read from
  /// which text the copy holds, without parsing it.
  String _pinLabel(AppLocalizations l10n, LyricsPinRow pin) {
    final synced = (pin.syncedText ?? '').trim().isNotEmpty;
    final plain = (pin.plainText ?? '').trim().isNotEmpty;
    return onlineSourceLabel(
      l10n,
      plugin: pin.providerName,
      synced: synced,
      instrumental: pin.instrumental && !synced && !plain,
    );
  }

  @override
  Future<void> open(BuildContext context, TrackId id) =>
      showLyricsForTrack(context, id, followsPlaying: false);
}
