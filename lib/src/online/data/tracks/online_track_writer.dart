import '../../../database/app_database.dart';
import '../../../database/track_snapshot.dart';
import '../../../library/data/playlists/playlist_repository.dart';
import '../../../media/domain/track_id.dart';
import '../../../plugins/data/store/plugin_config_store.dart';
import '../../../plugins/data/store/plugin_rows.dart';
import '../../../plugins/domain/logs/log_redaction.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../domain/contract/online_card.dart';
import '../../domain/tracks/cover_rule.dart';
import 'card_track_row.dart';
import 'plugin_source_rows.dart';

/// Most cards one [OnlineTrackWriter.upsertCards] call takes.
const maxUpsertCards = 200;

/// Most cards one [OnlineTrackWriter.saveAsNewPlaylist] call takes.
const maxPlaylistCards = 1000;

/// The plugin cannot be written for: not installed, removed, not a
/// streaming plugin, or its stored `plugin.json` no longer parses.
class OnlineWriteRefused implements Exception {
  const OnlineWriteRefused(this.reason);

  /// A fixed text; never plugin data.
  final String reason;

  @override
  String toString() => 'OnlineWriteRefused($reason)';
}

class SavedOnlinePlaylist {
  const SavedOnlinePlaylist({
    required this.playlistUid,
    required this.trackCount,
  });

  final String playlistUid;
  final int trackCount;
}

/// Writes online tracks to the library, only when the user refers to them
/// (plays a list, saves it as a playlist). Every call is one transaction: a
/// failure leaves no row behind.
class OnlineTrackWriter {
  OnlineTrackWriter(
    this._db,
    this._plugins,
    this._config, {
    int Function()? now,
  }) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final PluginRows _plugins;
  final PluginConfigStore _config;
  final int Function() _now;

  /// Creates or refreshes the track rows of [cards] (1 to
  /// [maxUpsertCards], tracks only) of the install [installId] and returns
  /// their ids in the order of [cards].
  Future<List<TrackId>> upsertCards(
    String installId,
    List<OnlineCard> cards,
  ) async {
    _checkCount(cards, maxUpsertCards);
    return _write(installId, cards, (db, ids, now) async => ids);
  }

  /// Writes [cards] (1 to [maxPlaylistCards]; a repeated id counts once,
  /// the first wins) and a new playlist [name] holding them, in one
  /// transaction. A bad name throws and nothing is kept.
  Future<SavedOnlinePlaylist> saveAsNewPlaylist(
    String installId, {
    required String name,
    required List<OnlineCard> cards,
  }) async {
    _checkCount(cards, maxPlaylistCards);
    final seen = <String>{};
    final unique = [
      for (final card in cards)
        if (seen.add(card.id)) card,
    ];
    final now = _now();
    return _write(installId, unique, (db, ids, _) async {
      final uid = await PlaylistRepository(
        db,
        now: () => now,
      ).createPlaylist(name: name, tracks: ids);
      return SavedOnlinePlaylist(playlistUid: uid, trackCount: ids.length);
    }, now: now);
  }

  void _checkCount(List<OnlineCard> cards, int max) {
    if (cards.isEmpty || cards.length > max) {
      throw ArgumentError.value(cards.length, 'cards', 'must be 1 to $max');
    }
  }

  Future<R> _write<R>(
    String installId,
    List<OnlineCard> cards,
    Future<R> Function(AppDatabase db, List<TrackId> ids, int now) finish, {
    int? now,
  }) async {
    // Plugin store reads first: nothing of it runs inside the transaction.
    final row = await _plugins.liveById(installId);
    if (row == null || row.kind != PluginKind.streaming.wire) {
      throw const OnlineWriteRefused('plugin not installed or not streaming');
    }
    final manifest = _plugins.manifestOf(row);
    if (manifest == null) {
      throw const OnlineWriteRefused('plugin manifest unreadable');
    }
    final data = await _config.read(installId);
    final hosts = manifest.hosts.toSet();
    final configValues = userEnteredStrings(
      manifest.config,
      data.values,
    ).toList();
    final stamp = now ?? _now();
    return _db.transaction(() async {
      final source = await ensurePluginSource(_db, row, now: stamp);
      final ids = <TrackId>[];
      for (final card in cards) {
        final id = await upsertTrackSnapshot(
          _db,
          _db.tracks,
          cardTrackRow(
            card,
            sourceId: source.sourceId,
            sourceUid: source.sourceUid,
            coverUrl: persistableCoverUrl(
              card.artworkUrl,
              manifestHosts: hosts,
              configValues: configValues,
            ),
            now: stamp,
          ),
        );
        ids.add(TrackId(id));
      }
      return finish(_db, ids, stamp);
    });
  }
}
