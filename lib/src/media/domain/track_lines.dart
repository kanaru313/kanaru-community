import 'track_info.dart';

/// The artist line of a track: every artist of the tag in order, else the
/// single artist field.
String trackArtistLine(TrackInfo info) {
  if (info.artists.isNotEmpty) return info.artists.join(', ');
  return info.artist ?? '';
}

/// `album • year`, whichever parts exist.
String trackAlbumLine(TrackInfo info) {
  final album = info.album;
  final year = info.year;
  return [
    if (album != null && album.isNotEmpty) album,
    if (year != null) '$year',
  ].join(' • ');
}
