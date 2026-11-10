import 'native_failure.dart';

/// The tags of one file (pure mirror of the Rust DTO). Text is already capped
/// by Rust; blank strings are possible.
class TagFields {
  const TagFields({
    this.title,
    this.artists = const [],
    this.album,
    this.albumArtists = const [],
    this.genres = const [],
    this.composer,
    this.year,
    this.trackNo,
    this.trackTotal,
    this.discNo,
    this.discTotal,
    this.titleSort,
    this.artistSort,
    this.albumSort,
    this.languageTag,
    this.detectedLanguage,
    this.comment,
    this.durationMs,
    this.bitrate,
    this.sampleRate,
    this.bitDepth,
    this.channels,
    this.codec,
  });

  final String? title;
  final List<String> artists;
  final String? album;
  final List<String> albumArtists;
  final List<String> genres;
  final String? composer;
  final int? year;
  final int? trackNo;
  final int? trackTotal;
  final int? discNo;
  final int? discTotal;
  final String? titleSort;
  final String? artistSort;
  final String? albumSort;

  /// The language tag as written; null without one.
  final String? languageTag;

  /// Language detected from the title; only set when there is no tag.
  final String? detectedLanguage;
  final String? comment;
  final int? durationMs;
  final int? bitrate;
  final int? sampleRate;
  final int? bitDepth;
  final int? channels;
  final String? codec;
}

/// The result of reading one file: [fields] or [error].
class TagRead {
  const TagRead({required this.path, this.fields, this.error});

  final String path;
  final TagFields? fields;
  final NativeFailure? error;
}
