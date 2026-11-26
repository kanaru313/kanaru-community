import '../../../media/domain/track_id.dart';

/// One visible library track as search and lookup results show it. Not a
/// `TrackSnapshot`: it carries only what a list line or a tool answer needs.
class TrackHit {
  const TrackHit({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.year,
  });

  final TrackId id;
  final String title;
  final String? artist;
  final String? album;
  final int? year;

  @override
  bool operator ==(Object other) =>
      other is TrackHit &&
      other.id == id &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.year == year;

  @override
  int get hashCode => Object.hash(id, title, artist, album, year);

  @override
  String toString() => 'TrackHit($id, $title, $artist, $album, $year)';
}
