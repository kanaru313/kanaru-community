/// What a card stands for.
enum OnlineCardKind { track, album, playlist, artist }

/// A named thing a card points to (an artist or an album); [id] is the
/// plugin's own id when it gave a valid one.
class CardRef {
  const CardRef({this.id, required this.name});

  final String? id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is CardRef && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'CardRef($id)';
}

/// One search result as a plugin gave it, after the reader's checks.
class OnlineCard {
  const OnlineCard({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle,
    this.artist,
    this.artists = const [],
    this.album,
    this.duration,
    this.artworkUrl,
    this.webUrl,
  });

  final OnlineCardKind kind;

  /// The plugin's id, handed back to it exactly as it came.
  final String id;
  final String title;
  final String? subtitle;
  final String? artist;
  final List<CardRef> artists;
  final CardRef? album;
  final Duration? duration;
  final String? artworkUrl;
  final String? webUrl;

  @override
  bool operator ==(Object other) =>
      other is OnlineCard &&
      other.kind == kind &&
      other.id == id &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.artist == artist &&
      _sameList(other.artists, artists) &&
      other.album == album &&
      other.duration == duration &&
      other.artworkUrl == artworkUrl &&
      other.webUrl == webUrl;

  @override
  int get hashCode => Object.hash(
    kind,
    id,
    title,
    subtitle,
    artist,
    Object.hashAll(artists),
    album,
    duration,
    artworkUrl,
    webUrl,
  );

  /// No titles or URLs: cards end up in logs.
  @override
  String toString() => 'OnlineCard(${kind.name}, $id)';
}

bool _sameList(List<CardRef> a, List<CardRef> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
