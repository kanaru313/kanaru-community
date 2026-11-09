import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

enum TrackAvailability { present, missing, hidden, remote }

final RegExp _cueSuffix = RegExp(r'#\d+$');

/// Upper-case file extension of a locator, for [TrackInfo.format]. Only a
/// trailing CUE suffix ('#NN') is stripped ('C# Minor.flac' keeps its name).
/// Null when there is no extension or the file is a '.cue' sheet.
String? formatFromLocator(String locator) {
  final path = locator.replaceFirst(_cueSuffix, '');
  final name = path.substring(path.lastIndexOf('/') + 1);
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return null;
  final ext = name.substring(dot + 1).toLowerCase();
  return ext == 'cue' ? null : ext.toUpperCase();
}

/// What every list, the player and media controls show for one track.
/// Playback resolves the file path separately; the UI never needs it.
class TrackInfo {
  const TrackInfo({
    required this.id,
    required this.title,
    required this.status,
    required this.relPath,
    this.artist,
    this.album,
    this.albumArtist,
    this.artists = const [],
    this.year,
    this.trackNo,
    this.discNo,
    this.durationMs,
    this.coverKey,
    this.albumKey,
    this.genre,
    this.language,
    this.languageDetected = false,
    this.format,
    this.sampleRate,
    this.bitrate,
    this.bitDepth,
    this.playCount = 0,
  });

  final TrackId id;
  final String title;
  final String? artist;
  final String? album;
  final String? albumArtist;

  /// From track_artists, in tag order; empty = use [artist].
  final List<String> artists;
  final int? year;
  final int? trackNo;
  final int? discNo;
  final int? durationMs;
  final String? coverKey;

  /// Null when the track has no album.
  final AlbumKey? albumKey;
  final String? genre;
  final String? language;
  final bool languageDetected;

  /// Upper-case codec/extension ('FLAC'): the `codec` column (database phase),
  /// falling back to `formatFromLocator(rel_path)`.
  final String? format;
  final int? sampleRate;
  final int? bitrate;
  final int? bitDepth;
  final int playCount;
  final TrackAvailability status;
  final String relPath;

  @override
  bool operator ==(Object other) {
    if (other is! TrackInfo) return false;
    if (artists.length != other.artists.length) return false;
    for (var i = 0; i < artists.length; i++) {
      if (artists[i] != other.artists[i]) return false;
    }
    return id == other.id &&
        title == other.title &&
        artist == other.artist &&
        album == other.album &&
        albumArtist == other.albumArtist &&
        year == other.year &&
        trackNo == other.trackNo &&
        discNo == other.discNo &&
        durationMs == other.durationMs &&
        coverKey == other.coverKey &&
        albumKey == other.albumKey &&
        genre == other.genre &&
        language == other.language &&
        languageDetected == other.languageDetected &&
        format == other.format &&
        sampleRate == other.sampleRate &&
        bitrate == other.bitrate &&
        bitDepth == other.bitDepth &&
        playCount == other.playCount &&
        status == other.status &&
        relPath == other.relPath;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    artist,
    album,
    albumArtist,
    Object.hashAll(artists),
    year,
    trackNo,
    discNo,
    durationMs,
    coverKey,
    albumKey,
    genre,
    language,
    languageDetected,
    format,
    sampleRate,
    bitrate,
    bitDepth,
    playCount,
    status,
    relPath,
  ]);

  @override
  String toString() => 'TrackInfo(${id.value}, $title)';
}
