/// Where playback started; written to play_log (context_kind/ref) and shown
/// as the source name on Now Playing ("Playlist · Chill tối thứ 7").
enum PlayContextKind {
  songs,
  album,
  artist,
  genre,
  language,
  folder,
  favorites,
  selection,
  queue,
}

/// [ref] is the encoded key (album/artist/genre/language) or the folder
/// `'<sourceUid>:<folderKey>'`; [label] is the display name captured at play
/// time (no lookup later).
class PlayContext {
  const PlayContext(this.kind, {this.ref, this.label});

  final PlayContextKind kind;
  final String? ref;
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is PlayContext &&
      other.kind == kind &&
      other.ref == ref &&
      other.label == label;

  @override
  int get hashCode => Object.hash(kind, ref, label);

  @override
  String toString() => 'PlayContext($kind, ref: $ref, label: $label)';
}
