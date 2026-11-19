import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_info.dart';

/// An album that can lend its cover to another item.
typedef AlbumCoverCandidate = ({
  AlbumKey key,
  String title,
  int? year,
  String coverKey,
});

/// Distinct albums of [tracks], in the given order, that have a cover: the
/// suggestions of the cover dialog for a playlist. A track without an album
/// or without a cover is skipped, an album seen again counts once (its first
/// track with a cover wins), and at most [limit] albums are returned.
List<AlbumCoverCandidate> albumCoverCandidates(
  Iterable<TrackInfo> tracks,
  int limit,
) {
  final seen = <String>{};
  final out = <AlbumCoverCandidate>[];
  for (final track in tracks) {
    if (out.length >= limit) break;
    final album = track.albumKey;
    final cover = track.coverKey;
    if (album == null || cover == null) continue;
    if (!seen.add(album.encode())) continue;
    out.add((
      key: album,
      title: track.album ?? '',
      year: track.year,
      coverKey: cover,
    ));
  }
  return out;
}
