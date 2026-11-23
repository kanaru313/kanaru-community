/// What to look for: the tags of a song, or the free text of the manual
/// search (no title: the title field stays null and the ranking is manual).
class LyricsQuery {
  const LyricsQuery({this.title, this.artist, this.album, this.duration});

  final String? title;

  /// The library artist tag, possibly several names (`A; B`).
  final String? artist;
  final String? album;
  final Duration? duration;
}

/// The lyrics of a [LyricsCandidate]. [syncedLrc] and [plain] are null when
/// absent or blank.
class LyricsBody {
  const LyricsBody({this.syncedLrc, this.plain, this.instrumental = false});

  final String? syncedLrc;
  final String? plain;

  /// The plugin says the song has no words.
  final bool instrumental;

  bool get hasLyrics => syncedLrc != null || plain != null;

  /// Something to use: words or the instrumental flag.
  bool get isUsable => hasLyrics || instrumental;
}

/// A result of a plugin's `search`, already checked by the reader.
class LyricsCandidate {
  const LyricsCandidate({
    required this.providerId,
    required this.remoteId,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.body,
  });

  /// Install id of the plugin that returned it.
  final String providerId;

  /// Identifies the result inside its plugin.
  final String remoteId;
  final String title;
  final String artist;
  final String? album;
  final Duration? duration;

  /// Null when the search answered without lyrics (a two-step source).
  final LyricsBody? body;

  bool get hasBody => body?.isUsable ?? false;

  /// What a rejected result is remembered by.
  ({String providerId, String remoteId}) get ref =>
      (providerId: providerId, remoteId: remoteId);

  LyricsCandidate withBody(LyricsBody? body) => LyricsCandidate(
    providerId: providerId,
    remoteId: remoteId,
    title: title,
    artist: artist,
    album: album,
    duration: duration,
    body: body,
  );
}
