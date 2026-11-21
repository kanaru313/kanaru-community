import 'lyrics.dart';

/// Which local source wins on equal quality (setting `lyrics.local_first`).
enum LocalFirst { tag, lrc }

/// The outcome of [pickLocalLyrics]: what is shown, and what each source has
/// (the "Lyrics for this song" modal describes them).
class LocalPick {
  const LocalPick({this.shown, this.tag, this.lrc});

  final Lyrics? shown;
  final Lyrics? tag;
  final Lyrics? lrc;
}

/// The local selection order: synced in the preferred source, synced in the
/// other, plain in the preferred, plain in the other, else nothing.
LocalPick pickLocalLyrics({
  Lyrics? tag,
  Lyrics? lrc,
  required LocalFirst first,
}) {
  final ordered = first == LocalFirst.tag ? [tag, lrc] : [lrc, tag];
  Lyrics? shown;
  for (final synced in [true, false]) {
    for (final candidate in ordered) {
      if (candidate != null && candidate.synced == synced) {
        shown = candidate;
        break;
      }
    }
    if (shown != null) break;
  }
  return LocalPick(shown: shown, tag: tag, lrc: lrc);
}
