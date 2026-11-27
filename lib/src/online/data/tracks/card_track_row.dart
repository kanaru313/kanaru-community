import 'package:drift/drift.dart' show Value;

import '../../../database/row_uids.dart';
import '../../../database/tables.dart';
import '../../../media/domain/library_keys.dart';
import '../../domain/contract/item_ref.dart';
import '../../domain/contract/online_card.dart';

/// The snapshot row of a track card. `locator` and `rel_path` are the
/// plugin's id as it came (no format is derived from it). Optional fields
/// are left absent when the card has none, so a later write never erases
/// what an earlier one stored. Never sets codec, status or user columns, and
/// no artist rows are written.
///
/// Throws [ArgumentError] for a card that is not a track or whose id looks
/// like a URL.
TracksCompanion cardTrackRow(
  OnlineCard card, {
  required int sourceId,
  required String sourceUid,
  required String? coverUrl,
  required int now,
}) {
  if (card.kind != OnlineCardKind.track) {
    throw ArgumentError.value(card.kind.name, 'card', 'only tracks are saved');
  }
  if (isUrlShapedId(card.id)) {
    throw ArgumentError.value('<id>', 'card.id', 'looks like a URL');
  }
  final artist = card.artist;
  final album = card.album?.name;
  final key = album == null
      ? null
      : albumKeyFor(album: album, artists: [artist ?? '']);
  return TracksCompanion.insert(
    uid: trackUid(sourceUid, card.id),
    sourceId: sourceId,
    locator: card.id,
    relPath: card.id,
    title: card.title,
    titleSearch: Value(searchForm(card.title)),
    titleSort: Value(sortForm(card.title)),
    artist: Value.absentIfNull(artist),
    artistSearch: Value.absentIfNull(
      artist == null ? null : searchForm(artist),
    ),
    album: album == null ? const Value.absent() : Value(album),
    albumSearch: album == null
        ? const Value.absent()
        : Value(searchForm(album)),
    albumTitleKey: album == null ? const Value.absent() : Value(key?.titleKey),
    albumArtistKey: album == null
        ? const Value.absent()
        : Value(key?.artistKey),
    durationMs: Value.absentIfNull(card.duration?.inMilliseconds),
    coverUrl: Value.absentIfNull(coverUrl),
    addedAt: now,
    updatedAt: now,
  );
}
