/// One album of the Albums list. [key] is the encoded `AlbumKey`.
class AlbumSummary {
  const AlbumSummary({
    required this.key,
    required this.title,
    required this.artist,
    required this.year,
    required this.trackCount,
    required this.durationMs,
    required this.coverKey,
    required this.addedAt,
  });

  final String key;
  final String title;
  final String? artist;
  final int? year;
  final int trackCount;
  final int durationMs;
  final String? coverKey;
  final int addedAt;

  @override
  bool operator ==(Object other) =>
      other is AlbumSummary &&
      other.key == key &&
      other.title == title &&
      other.artist == artist &&
      other.year == year &&
      other.trackCount == trackCount &&
      other.durationMs == durationMs &&
      other.coverKey == coverKey &&
      other.addedAt == addedAt;

  @override
  int get hashCode => Object.hash(
    key,
    title,
    artist,
    year,
    trackCount,
    durationMs,
    coverKey,
    addedAt,
  );
}

/// One artist of the Artists list. [key] is the encoded `ArtistKey`.
class ArtistSummary {
  const ArtistSummary({
    required this.key,
    required this.name,
    required this.trackCount,
    required this.albumCount,
    required this.durationMs,
    required this.coverKey,
  });

  final String key;
  final String name;
  final int trackCount;
  final int albumCount;
  final int durationMs;
  final String? coverKey;

  @override
  bool operator ==(Object other) =>
      other is ArtistSummary &&
      other.key == key &&
      other.name == name &&
      other.trackCount == trackCount &&
      other.albumCount == albumCount &&
      other.durationMs == durationMs &&
      other.coverKey == coverKey;

  @override
  int get hashCode =>
      Object.hash(key, name, trackCount, albumCount, durationMs, coverKey);
}

/// One genre of the Genres list.
class GenreSummary {
  const GenreSummary({
    required this.key,
    required this.name,
    required this.trackCount,
  });

  final String key;
  final String name;
  final int trackCount;

  @override
  bool operator ==(Object other) =>
      other is GenreSummary &&
      other.key == key &&
      other.name == name &&
      other.trackCount == trackCount;

  @override
  int get hashCode => Object.hash(key, name, trackCount);
}

/// One language of the Languages list; [code] null groups tracks without one.
/// [detectedCount] is how many of [trackCount] got the language by detection.
class LanguageSummary {
  const LanguageSummary({
    required this.code,
    required this.trackCount,
    required this.detectedCount,
  });

  final String? code;
  final int trackCount;
  final int detectedCount;

  @override
  bool operator ==(Object other) =>
      other is LanguageSummary &&
      other.code == code &&
      other.trackCount == trackCount &&
      other.detectedCount == detectedCount;

  @override
  int get hashCode => Object.hash(code, trackCount, detectedCount);
}
