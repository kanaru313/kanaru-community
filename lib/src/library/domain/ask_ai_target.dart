/// What a "Ask AI" entry of a library menu, the now-playing screen or a
/// selection hands to the chat. Pure data: the AI module turns it into a chip
/// and reads the tracks itself, so this file knows nothing about the chat.
sealed class AskAiTarget {
  const AskAiTarget();

  /// The song loaded in the player.
  const factory AskAiTarget.nowPlaying() = AskAiNowPlaying;

  /// One song.
  const factory AskAiTarget.song(AskAiTrack track) = AskAiSong;

  /// A selection of songs (any list selection).
  ///
  /// [total] is how many songs are selected when [tracks] was cut to
  /// [askAiMaxSongs]; null = all of them.
  const factory AskAiTarget.songs(List<AskAiTrack> tracks, {int? total}) =
      AskAiSongs;

  /// An album; [key] is the library's album key text, [label] what the chip
  /// shows.
  const factory AskAiTarget.album(String key, String label) = AskAiAlbum;

  const factory AskAiTarget.artist(String key, String label) = AskAiArtist;

  /// A genre ([key] is the stored `genre_key`).
  const factory AskAiTarget.genre(String key, String label) = AskAiGenre;

  /// A language ([code] is ISO 639-3; null = songs without a language).
  const factory AskAiTarget.language(String? code, String label) =
      AskAiLanguage;

  /// A playlist by its uid (the AI module maps it to the id the model uses).
  const factory AskAiTarget.playlist(String uid, String label) = AskAiPlaylist;
}

/// Most songs one "Ask AI" chip carries: the chat sends no more than this
/// (the engine's `chipMaxRows`, kept equal by a test).
const int askAiMaxSongs = 200;

/// The songs of a selection by id alone, at most [askAiMaxSongs]. No titles:
/// nothing is read from the library when a menu opens or the selection
/// changes; the chat reads the rows when the message is sent.
List<AskAiTrack> askAiTracksOfIds(Iterable<int> ids) => [
  for (final id in ids.take(askAiMaxSongs)) AskAiTrack(id: id, title: ''),
];

/// A track a target names: its library id and the text the chip shows.
class AskAiTrack {
  const AskAiTrack({
    required this.id,
    required this.title,
    this.artist = '',
    this.album,
  });

  final int id;
  final String title;
  final String artist;
  final String? album;

  @override
  bool operator ==(Object other) =>
      other is AskAiTrack &&
      other.id == id &&
      other.title == title &&
      other.artist == artist &&
      other.album == album;

  @override
  int get hashCode => Object.hash(id, title, artist, album);
}

class AskAiNowPlaying extends AskAiTarget {
  const AskAiNowPlaying();
}

class AskAiSong extends AskAiTarget {
  const AskAiSong(this.track);

  final AskAiTrack track;
}

class AskAiSongs extends AskAiTarget {
  const AskAiSongs(this.tracks, {this.total});

  final List<AskAiTrack> tracks;

  /// The real selection size when [tracks] was cut; null = all of them.
  final int? total;
}

class AskAiAlbum extends AskAiTarget {
  const AskAiAlbum(this.key, this.label);

  final String key;
  final String label;
}

class AskAiArtist extends AskAiTarget {
  const AskAiArtist(this.key, this.label);

  final String key;
  final String label;
}

class AskAiGenre extends AskAiTarget {
  const AskAiGenre(this.key, this.label);

  final String key;
  final String label;
}

class AskAiLanguage extends AskAiTarget {
  const AskAiLanguage(this.code, this.label);

  final String? code;
  final String label;
}

class AskAiPlaylist extends AskAiTarget {
  const AskAiPlaylist(this.uid, this.label);

  final String uid;
  final String label;
}
