import 'package:drift/drift.dart' show Value;

import '../../../database/database.dart';
import '../../../media/domain/library_keys.dart';
import '../../../storage/domain/local_folder_listing.dart';
import '../../domain/scan/artist_split.dart';
import '../../domain/scan/lrc_match.dart';
import '../../domain/scan/native_failure.dart';
import '../../domain/scan/scan_diff.dart';
import '../../domain/scan/scan_folder.dart';
import '../../domain/scan/scan_versions.dart';
import '../../domain/scan/tag_read.dart';

/// What to write to `track_details` for a track.
class DetailsPatch {
  const DetailsPatch({
    this.comment = const Value.absent(),
    required this.lrcLocator,
    required this.lrcRevision,
  });

  /// Absent leaves the stored comment alone (sidecar-only updates).
  final Value<String?> comment;
  final String? lrcLocator;
  final String? lrcRevision;
}

/// One track row ready for the writer.
class BuiltTrack {
  const BuiltTrack({required this.row, required this.artists, this.details});

  final TracksCompanion row;
  final List<({String key, String name})> artists;

  /// Null leaves `track_details` alone.
  final DetailsPatch? details;
}

String? _blank(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

String? _joined(List<String> values) {
  final parts = [for (final v in values) ?_blank(v)];
  return parts.isEmpty ? null : parts.join('; ');
}

/// The file name without its folder and last extension.
String stemOf(String locator) {
  final name = locator.substring(locator.lastIndexOf('/') + 1);
  final dot = name.lastIndexOf('.');
  return dot <= 0 ? name : name.substring(0, dot);
}

/// Builds the row for [file] from its tag [read], following the stored-column
/// rule of `docs/system-architecture-library.md` (every derived column comes
/// from the `media/domain/library_keys.dart` functions).
///
/// A [TagRead] with an error gives a filename-only row: a permanent error
/// records the current pass versions, a transient one leaves `tags_version`
/// at 0 and mtime, size and revision NULL so the next scan reads the file
/// again. An existing row with a transient error is never written (throws
/// [ArgumentError]: the caller skips it).
///
/// `cover_scan_version` is reset to 0 for a new row and when the revision
/// changed, and left alone otherwise (a keys-only re-read keeps covers).
BuiltTrack buildTrackRow({
  required ScanFolder folder,
  required ListedFile file,
  required TagRead read,
  required int now,
  LrcMatch? lrc,
  StoredTrackRow? stored,
}) {
  final error = read.error;
  if (error != null && error.transient && stored != null) {
    throw ArgumentError('a transient error on an existing row is not written');
  }
  final f = error == null ? read.fields : null;
  final transientNew = error != null && error.transient;
  final locator = file.locator;

  final title = _blank(f?.title) ?? stemOf(locator);
  final rawArtists = [
    for (final a in f?.artists ?? const <String>[]) ?_blank(a),
  ];
  final names = [for (final a in artistsForRow(rawArtists)) a.name];
  final albumArtist = _joined(f?.albumArtists ?? const []);
  final albumText = _blank(f?.album);
  final albumKey = albumText == null
      ? null
      : albumKeyFor(album: albumText, albumArtist: albumArtist, artists: names);
  final album = albumKey == null ? null : albumText;
  final genreText = _joined(f?.genres ?? const []);
  final genreKey = genreText == null ? null : groupKey(genreText);
  final genre = genreKey == null || genreKey.isEmpty ? null : genreText;
  final albumArtistForSearch =
      albumArtist ?? (names.isEmpty ? null : names.first);
  final tagLanguage = languageKey(f?.languageTag);
  final language = tagLanguage ?? languageKey(f?.detectedLanguage);
  final revision = revisionOf(file.mtimeMs, file.sizeBytes);
  final resetCovers = stored == null || stored.revision != revision;

  final row = TracksCompanion(
    uid: Value(trackUid(folder.sourceUid, locator)),
    sourceId: Value(folder.sourceId),
    locator: Value(locator),
    relPath: Value(locator),
    revision: Value(transientNew ? null : revision),
    mtimeMs: Value(transientNew ? null : file.mtimeMs),
    sizeBytes: Value(transientNew ? null : file.sizeBytes),
    songKey: Value(songKey(title: title, artists: names)),
    title: Value(title),
    titleSort: Value(sortForm(_blank(f?.titleSort) ?? title)),
    titleSearch: Value(searchForm(title)),
    artist: Value(rawArtists.isEmpty ? null : rawArtists.join('; ')),
    album: Value(album),
    albumArtist: Value(albumArtist),
    genre: Value(genre),
    composer: Value(_blank(f?.composer)),
    language: Value(language),
    artistSort: Value(_sortOrNull(f?.artistSort)),
    albumSort: Value(_sortOrNull(f?.albumSort)),
    artistSearch: Value(names.isEmpty ? null : searchForm(names.join(' '))),
    albumSearch: Value(album == null ? null : searchForm(album)),
    albumArtistSearch: Value(
      albumArtistForSearch == null ? null : searchForm(albumArtistForSearch),
    ),
    genreSearch: Value(genre == null ? null : searchForm(genre)),
    genreKey: Value(genre == null ? null : genreKey),
    languageDetected: Value(tagLanguage == null && language != null ? 1 : 0),
    albumArtistKey: Value(albumKey?.artistKey),
    albumTitleKey: Value(albumKey?.titleKey),
    trackNo: Value(f?.trackNo),
    trackTotal: Value(f?.trackTotal),
    discNo: Value(f?.discNo),
    discTotal: Value(f?.discTotal),
    year: Value(f?.year),
    durationMs: Value(f?.durationMs),
    bitrate: Value(f?.bitrate),
    sampleRate: Value(f?.sampleRate),
    bitDepth: Value(f?.bitDepth),
    channels: Value(f?.channels),
    codec: Value(_blank(f?.codec)),
    tagsVersion: Value(transientNew ? 0 : tagsPassVersion),
    keysVersion: const Value(libraryKeysVersion),
    scanError: Value(error?.kind),
    coverScanVersion: resetCovers ? const Value(0) : const Value.absent(),
    addedAt: Value(now),
    updatedAt: Value(now),
  );

  final comment = _blank(f?.comment);
  final writeDetails =
      comment != null || lrc != null || (stored?.hasDetails ?? false);
  return BuiltTrack(
    row: row,
    artists: artistsForRow(rawArtists),
    details: writeDetails
        ? DetailsPatch(
            comment: Value(comment),
            lrcLocator: lrc?.locator,
            lrcRevision: lrc?.revision,
          )
        : null,
  );
}

String? _sortOrNull(String? tag) {
  final t = _blank(tag);
  return t == null ? null : sortForm(t);
}

/// Whether [failure] makes the read a "not listed" case rather than a row.
bool isNotListed(NativeFailure? failure) => failure?.isNotFound ?? false;
