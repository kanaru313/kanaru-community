import '../../../library/domain/ask_ai_target.dart';
import '../conversation/parts.dart';
import '../conversation/track_ref_snapshot.dart';
import '../settings/tool_groups.dart';

/// A chip as the composer holds it before send: what it points at, not yet
/// its data. For a playlist [ref] is the playlist's uid until the resolver
/// swaps it for the id the model uses.
class ChipRef {
  const ChipRef({
    required this.kind,
    this.ref,
    this.label,
    this.tracks = const [],
  });

  final ChipKind kind;
  final String? ref;
  final String? label;
  final List<TrackRefSnapshot> tracks;

  /// The privacy group that must be on to attach this chip.
  AiToolGroup get group => chipGroup(kind);
}

/// Chip kind -> privacy group. There is no lyrics chip.
AiToolGroup chipGroup(ChipKind kind) => switch (kind) {
  ChipKind.nowPlaying => AiToolGroup.nowPlaying,
  ChipKind.song ||
  ChipKind.songs ||
  ChipKind.album ||
  ChipKind.artist ||
  ChipKind.genre ||
  ChipKind.language => AiToolGroup.trackInfo,
  ChipKind.playlist => AiToolGroup.playlists,
};

TrackRefSnapshot _snap(AskAiTrack t) => TrackRefSnapshot(
  trackId: t.id,
  title: t.title,
  artist: t.artist,
  album: t.album,
);

/// The one mapping from a library "Ask AI" target to a chip.
ChipRef chipRefOf(AskAiTarget target) => switch (target) {
  AskAiNowPlaying() => const ChipRef(kind: ChipKind.nowPlaying),
  AskAiSong(:final track) => ChipRef(
    kind: ChipKind.song,
    label: track.title,
    tracks: [_snap(track)],
  ),
  AskAiSongs(:final tracks, :final total) => ChipRef(
    kind: ChipKind.songs,
    // Only a cut selection names its real size (the chip then shows it).
    label: total != null && total > tracks.length ? '$total' : null,
    tracks: [for (final t in tracks) _snap(t)],
  ),
  AskAiAlbum(:final key, :final label) => ChipRef(
    kind: ChipKind.album,
    ref: key,
    label: label,
  ),
  AskAiArtist(:final key, :final label) => ChipRef(
    kind: ChipKind.artist,
    ref: key,
    label: label,
  ),
  AskAiGenre(:final key, :final label) => ChipRef(
    kind: ChipKind.genre,
    ref: key,
    label: label,
  ),
  // No language is the empty key.
  AskAiLanguage(:final code, :final label) => ChipRef(
    kind: ChipKind.language,
    ref: code ?? '',
    label: label,
  ),
  AskAiPlaylist(:final uid, :final label) => ChipRef(
    kind: ChipKind.playlist,
    ref: uid,
    label: label,
  ),
};
