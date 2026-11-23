import 'package:flutter/widgets.dart' show IconData;

/// Stable name of a row of the song info page, so tests and the view never
/// match on text.
enum InfoRowId {
  title,
  artists,
  album,
  albumArtist,
  genre,
  composer,
  released,
  trackNo,
  disc,
  language,
  comment,
  description,
  duration,
  format,
  codec,
  bitrate,
  sampleRate,
  bitDepth,
  channels,
  replayGain,
  path,
  musicFolder,
  size,
  modified,
  added,
  favorite,
  rating,
  plays,
  skips,
  firstPlayed,
  lastPlayed,
}

/// What a row's value is: plain text, links to library pages, the file path
/// with its buttons, or the favorite button.
enum InfoRowKind { text, links, path, favorite }

/// One underlined link of a row: [text], the library page it opens and the
/// spoken name.
class InfoLink {
  const InfoLink(this.text, this.location, this.semanticLabel);

  final String text;

  /// A `LibraryLocations` path.
  final String location;
  final String semanticLabel;

  @override
  bool operator ==(Object other) =>
      other is InfoLink &&
      other.text == text &&
      other.location == location &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(text, location, semanticLabel);
}

/// One label + value line, described without widgets.
class InfoRowSpec {
  const InfoRowSpec(
    this.id,
    this.label, {
    this.kind = InfoRowKind.text,
    this.value,
    this.copyText,
    this.links = const [],
    this.badge,
    this.soon = false,
    this.empty = false,
    this.missing = false,
    this.canReveal = false,
    this.muted = false,
  });

  final InfoRowId id;
  final String label;
  final InfoRowKind kind;

  /// Shown text; null for an empty field and for a row of links.
  final String? value;

  /// What copying takes when it differs from [value] ("2018-03", not
  /// "2018-03 · 8 years ago").
  final String? copyText;
  final List<InfoLink> links;

  /// Small label after the links ("tự nhận").
  final String? badge;

  /// Not available yet: dimmed, "Sắp có", never copied.
  final bool soon;

  /// No value: hidden unless the eye shows empty fields ("Không rõ").
  final bool empty;

  /// The file is gone: the path is struck through in `error`.
  final bool missing;

  /// Path row: show "open in the file manager" (the folder button is
  /// always there).
  final bool canReveal;

  /// A value that is a note, not data ("Chưa nghe lần nào"): quiet text.
  final bool muted;
}

/// A titled card of rows.
class InfoGroupSpec {
  const InfoGroupSpec(this.id, this.title, this.icon, this.rows);

  final String id;
  final String title;
  final IconData icon;
  final List<InfoRowSpec> rows;
}
