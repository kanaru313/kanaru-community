/// What a streaming plugin offers beyond `search` and `stream`, which every
/// streaming manifest must have.
class OnlineCapabilities {
  const OnlineCapabilities({
    this.autocomplete = false,
    this.home = false,
    this.genre = false,
    this.album = false,
    this.playlist = false,
    this.artist = false,
    this.related = false,
    this.resolve = false,
  });

  factory OnlineCapabilities.fromScripts(Iterable<String> scriptKeys) {
    final keys = scriptKeys.toSet();
    return OnlineCapabilities(
      autocomplete: keys.contains('autocomplete'),
      home: keys.contains('home'),
      genre: keys.contains('genre'),
      album: keys.contains('album'),
      playlist: keys.contains('playlist'),
      artist: keys.contains('artist'),
      related: keys.contains('related'),
      resolve: keys.contains('resolve'),
    );
  }

  final bool autocomplete;
  final bool home;
  final bool genre;
  final bool album;
  final bool playlist;
  final bool artist;
  final bool related;
  final bool resolve;
}
