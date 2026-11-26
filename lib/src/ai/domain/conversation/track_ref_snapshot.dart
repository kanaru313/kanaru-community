/// A track as a conversation remembers it: ids and text only, never a link
/// into the library, so a message stays readable after the track is gone.
class TrackRefSnapshot {
  const TrackRefSnapshot({
    required this.trackId,
    required this.title,
    this.artist = '',
    this.album,
  });

  final int trackId;
  final String title;

  /// Empty when the track has no artist.
  final String artist;
  final String? album;

  Map<String, Object?> toJson() => {
    'trackId': trackId,
    'title': title,
    'artist': artist,
    if (album != null) 'album': album,
  };

  /// Throws [FormatException] when a field has the wrong type.
  factory TrackRefSnapshot.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('track snapshot is not an object: $json');
    }
    final id = json['trackId'];
    final title = json['title'];
    final artist = json['artist'] ?? '';
    final album = json['album'];
    if (id is! int || title is! String || artist is! String) {
      throw FormatException('bad track snapshot: $json');
    }
    if (album != null && album is! String) {
      throw FormatException('bad track snapshot album: $album');
    }
    return TrackRefSnapshot(
      trackId: id,
      title: title,
      artist: artist,
      album: album as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TrackRefSnapshot &&
      other.trackId == trackId &&
      other.title == title &&
      other.artist == artist &&
      other.album == album;

  @override
  int get hashCode => Object.hash(trackId, title, artist, album);

  @override
  String toString() => 'TrackRefSnapshot($trackId, $title)';
}
