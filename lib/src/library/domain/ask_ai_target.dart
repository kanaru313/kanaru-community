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
  const factory AskAiTarget.songs(List<AskAiTrack> tracks) = AskAiSongs;

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
  const AskAiSongs(this.tracks);

  final List<AskAiTrack> tracks;
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
