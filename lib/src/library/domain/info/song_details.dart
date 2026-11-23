import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_id.dart';
import '../browse/menu_targets.dart';
import 'release_date.dart';

/// Whether the file was seen in the last complete scan.
enum SongFileStatus { present, missing }

/// Everything the song info page shows about one track, except the favorite
/// mark (the UI reads that from the favorites provider). Compared by value,
/// artists included, so a stream of it drops identical emissions.
class SongDetails {
  const SongDetails({
    required this.id,
    required this.title,
    required this.status,
    required this.addedAt,
    required this.folder,
    this.coverKey,
    this.artists = const [],
    this.album,
    this.albumKey,
    this.albumArtist,
    this.albumArtistKey,
    this.albumArtistDisplay,
    this.genre,
    this.genreKey,
    this.composer,
    this.year,
    this.releaseDate,
    this.trackNo,
    this.trackTotal,
    this.discNo,
    this.discTotal,
    this.language,
    this.languageDetected = false,
    this.comment,
    this.description,
    this.lrcLocator,
    this.durationMs,
    this.codec,
    this.format,
    this.bitrate,
    this.sampleRate,
    this.bitDepth,
    this.channels,
    this.path,
    this.sourceName,
    this.sourceRoot,
    this.sizeBytes,
    this.mtimeMs,
    this.missingSince,
    this.scanError,
    this.rating,
    this.playCount = 0,
    this.skipCount = 0,
    this.firstPlayedAt,
    this.lastPlayedAt,
  });

  final TrackId id;
  final String title;
  final String? coverKey;

  final List<ArtistRef> artists;

  final String? album;
  final AlbumKey? albumKey;

  /// Album artist as tagged, kept even when it equals a track artist.
  final String? albumArtist;

  /// Null without an album artist tag, even if the album has a key.
  final ArtistKey? albumArtistKey;

  final String? albumArtistDisplay;
  final String? genre;
  final String? genreKey;
  final String? composer;
  final int? year;

  final ReleaseDate? releaseDate;
  final int? trackNo;
  final int? trackTotal;
  final int? discNo;
  final int? discTotal;
  final String? language;

  final bool languageDetected;
  final String? comment;
  final String? description;

  final String? lrcLocator;
  final int? durationMs;
  final String? codec;

  final String? format;
  final int? bitrate;
  final int? sampleRate;
  final int? bitDepth;
  final int? channels;

  /// Absolute path without a CUE `#n` suffix; null when the source has no
  /// mounted local root.
  final String? path;

  /// For navigation only: `songCount` is not counted and stays 0.
  final FolderRef folder;
  final String? sourceName;
  final String? sourceRoot;
  final int? sizeBytes;
  final int? mtimeMs;
  final int addedAt;
  final SongFileStatus status;
  final int? missingSince;
  final String? scanError;
  final int? rating;
  final int playCount;
  final int skipCount;
  final int? firstPlayedAt;
  final int? lastPlayedAt;

  /// Cover placeholder seed; same rule as `TrackInfo.coverSeed`.
  String get coverSeed => albumKey?.encode() ?? title;

  List<Object?> get _props => [
    id,
    title,
    coverKey,
    artists,
    album,
    albumKey,
    albumArtist,
    albumArtistKey,
    albumArtistDisplay,
    genre,
    genreKey,
    composer,
    year,
    releaseDate,
    trackNo,
    trackTotal,
    discNo,
    discTotal,
    language,
    languageDetected,
    comment,
    description,
    lrcLocator,
    durationMs,
    codec,
    format,
    bitrate,
    sampleRate,
    bitDepth,
    channels,
    path,
    folder,
    sourceName,
    sourceRoot,
    sizeBytes,
    mtimeMs,
    addedAt,
    status,
    missingSince,
    scanError,
    rating,
    playCount,
    skipCount,
    firstPlayedAt,
    lastPlayedAt,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SongDetails) return false;
    final a = _props, b = other._props;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x is List && y is List) {
        if (!_sameList(x, y)) return false;
      } else if (x != y) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    for (final p in _props) p is List ? Object.hashAll(p) : p,
  ]);
}

bool _sameList(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
