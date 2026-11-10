// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/playback_stats.drift.dart' as i1;
import 'package:kanaru/src/database/tables/library_source_tables.drift.dart'
    as i2;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i3;
import 'package:kanaru/src/database/tables/playback_tables.drift.dart' as i4;
import 'package:kanaru/src/database/tables/library_track_search.drift.dart'
    as i5;
import 'package:kanaru/src/database/tables/library_collection_tables.drift.dart'
    as i6;
import 'package:kanaru/src/database/tables/library_cover_tables.drift.dart'
    as i7;
import 'package:kanaru/src/database/tables/custom_cover_triggers.drift.dart'
    as i8;
import 'package:kanaru/src/database/tables/extension_tables.drift.dart' as i9;
import 'package:drift/internal/modular.dart' as i10;

abstract class $AppDatabase extends i0.GeneratedDatabase {
  $AppDatabase(i0.QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final i1.PlayStatsCtl playStatsCtl = i1.PlayStatsCtl(this);
  late final i2.$SourcesTable sources = i2.$SourcesTable(this);
  late final i3.$TracksTable tracks = i3.$TracksTable(this);
  late final i4.$PlayLogTable playLog = i4.$PlayLogTable(this);
  late final i4.$PlayStatsTable playStats = i4.$PlayStatsTable(this);
  late final i4.$QueueEntriesTable queueEntries = i4.$QueueEntriesTable(this);
  late final i3.$TrackDetailsTable trackDetails = i3.$TrackDetailsTable(this);
  late final i3.$TrackArtistsTable trackArtists = i3.$TrackArtistsTable(this);
  late final i2.$SourceMountsTable sourceMounts = i2.$SourceMountsTable(this);
  late final i2.$ExcludedFoldersTable excludedFolders = i2
      .$ExcludedFoldersTable(this);
  late final i5.TrackSearch trackSearch = i5.TrackSearch(this);
  late final i6.$PlaylistsTable playlists = i6.$PlaylistsTable(this);
  late final i7.$CustomCoversTable customCovers = i7.$CustomCoversTable(this);
  late final i7.$CoverColorsTable coverColors = i7.$CoverColorsTable(this);
  late final i6.$PlaylistEntriesTable playlistEntries = i6
      .$PlaylistEntriesTable(this);
  late final i6.$SavedItemsTable savedItems = i6.$SavedItemsTable(this);
  late final i9.$ExtensionSchemaTable extensionSchema = i9
      .$ExtensionSchemaTable(this);
  i1.PlaybackStatsDrift get playbackStatsDrift =>
      i10.ReadDatabaseContainer(this)
          .accessor<i1.PlaybackStatsDrift>(i1.PlaybackStatsDrift.new);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    playStatsCtl,
    i1.$drift0,
    sources,
    tracks,
    playLog,
    playStats,
    i1.playLogStatsInsert,
    i1.playLogStatsUpdate,
    i1.playLogStatsDelete,
    queueEntries,
    i4.playLogTrackPlayed,
    i4.playLogPlayedAt,
    i4.playStatsLast,
    i4.queueEntriesTrack,
    i4.queueEntriesOrder,
    i4.queueEntriesShuffle,
    trackDetails,
    trackArtists,
    i3.tracksPresentTitle,
    i3.tracksStatus,
    i3.tracksAddedAt,
    i3.tracksAlbumKey,
    i3.tracksSongKey,
    i3.tracksRelPath,
    i3.tracksLanguage,
    i3.tracksTagsVersion,
    i3.tracksKeysVersion,
    i3.tracksCoverVersion,
    i3.tracksGenreKey,
    i3.trackArtistsTrack,
    sourceMounts,
    excludedFolders,
    i2.sourceMountsRoot,
    i2.excludedFoldersSource,
    trackSearch,
    i5.tracksSearchInsert,
    i5.tracksSearchDelete,
    i5.tracksSearchUpdate,
    playlists,
    customCovers,
    i8.customCoversPlaylistDelete,
    i8.customCoversPlaylistExistsInsert,
    i8.customCoversPlaylistExistsUpdate,
    coverColors,
    i7.customCoversCoverKey,
    playlistEntries,
    savedItems,
    i6.playlistsFavoritesUnique,
    i6.playlistsMoodNameUnique,
    i6.playlistsOriginUnique,
    i6.playlistsOriginSource,
    i6.playlistEntriesOrder,
    i6.playlistEntriesTrack,
    i6.savedItemsLookup,
    extensionSchema,
  ];
  @override
  i0.StreamQueryUpdateRules get streamUpdateRules =>
      const i0.StreamQueryUpdateRules([
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'play_log',
            limitUpdateKind: i0.UpdateKind.insert,
          ),
          result: [i0.TableUpdate('play_stats', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'play_log',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [
            i0.TableUpdate('play_stats', kind: i0.UpdateKind.update),
            i0.TableUpdate('play_stats', kind: i0.UpdateKind.delete),
            i0.TableUpdate('play_stats', kind: i0.UpdateKind.insert),
          ],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'play_log',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [
            i0.TableUpdate('play_stats', kind: i0.UpdateKind.update),
            i0.TableUpdate('play_stats', kind: i0.UpdateKind.delete),
          ],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'sources',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('source_mounts', kind: i0.UpdateKind.delete)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'sources',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [
            i0.TableUpdate('excluded_folders', kind: i0.UpdateKind.delete),
          ],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tracks',
            limitUpdateKind: i0.UpdateKind.insert,
          ),
          result: [i0.TableUpdate('track_search', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tracks',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('track_search', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tracks',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [i0.TableUpdate('track_search', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'playlists',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('custom_covers', kind: i0.UpdateKind.delete)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'custom_covers',
            limitUpdateKind: i0.UpdateKind.insert,
          ),
          result: [],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'custom_covers',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'playlists',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [
            i0.TableUpdate('playlist_entries', kind: i0.UpdateKind.delete),
          ],
        ),
      ]);
}

class $AppDatabaseManager {
  final $AppDatabase _db;
  $AppDatabaseManager(this._db);
  i1.$PlayStatsCtlTableManager get playStatsCtl =>
      i1.$PlayStatsCtlTableManager(_db, _db.playStatsCtl);
  i2.$$SourcesTableTableManager get sources =>
      i2.$$SourcesTableTableManager(_db, _db.sources);
  i3.$$TracksTableTableManager get tracks =>
      i3.$$TracksTableTableManager(_db, _db.tracks);
  i4.$$PlayLogTableTableManager get playLog =>
      i4.$$PlayLogTableTableManager(_db, _db.playLog);
  i4.$$PlayStatsTableTableManager get playStats =>
      i4.$$PlayStatsTableTableManager(_db, _db.playStats);
  i4.$$QueueEntriesTableTableManager get queueEntries =>
      i4.$$QueueEntriesTableTableManager(_db, _db.queueEntries);
  i3.$$TrackDetailsTableTableManager get trackDetails =>
      i3.$$TrackDetailsTableTableManager(_db, _db.trackDetails);
  i3.$$TrackArtistsTableTableManager get trackArtists =>
      i3.$$TrackArtistsTableTableManager(_db, _db.trackArtists);
  i2.$$SourceMountsTableTableManager get sourceMounts =>
      i2.$$SourceMountsTableTableManager(_db, _db.sourceMounts);
  i2.$$ExcludedFoldersTableTableManager get excludedFolders =>
      i2.$$ExcludedFoldersTableTableManager(_db, _db.excludedFolders);
  i5.$TrackSearchTableManager get trackSearch =>
      i5.$TrackSearchTableManager(_db, _db.trackSearch);
  i6.$$PlaylistsTableTableManager get playlists =>
      i6.$$PlaylistsTableTableManager(_db, _db.playlists);
  i7.$$CustomCoversTableTableManager get customCovers =>
      i7.$$CustomCoversTableTableManager(_db, _db.customCovers);
  i7.$$CoverColorsTableTableManager get coverColors =>
      i7.$$CoverColorsTableTableManager(_db, _db.coverColors);
  i6.$$PlaylistEntriesTableTableManager get playlistEntries =>
      i6.$$PlaylistEntriesTableTableManager(_db, _db.playlistEntries);
  i6.$$SavedItemsTableTableManager get savedItems =>
      i6.$$SavedItemsTableTableManager(_db, _db.savedItems);
  i9.$$ExtensionSchemaTableTableManager get extensionSchema =>
      i9.$$ExtensionSchemaTableTableManager(_db, _db.extensionSchema);
}
