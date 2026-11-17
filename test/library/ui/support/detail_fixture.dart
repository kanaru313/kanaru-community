import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

import 'dart:ui' show SemanticsFlag;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../browse/support/library_fixture.dart';
import 'library_harness.dart';

/// Writes an album of [tracks] numbered songs by [artist] (album artist too)
/// and returns the track ids in track order.
Future<List<int>> addAlbum(
  LibraryHarness h,
  String album,
  String artist, {
  int year = 2000,
  int tracks = 3,
  String? genre,
  String? language,
  bool languageDetected = false,
  List<String>? trackArtists,
  String? albumArtist,
  String? coverKey,
}) async => [
  for (var n = 1; n <= tracks; n++)
    await addLibraryTrack(
      h.db,
      source: h.sourceId,
      locator: '$album/$n.flac',
      title: '$album $n',
      artists: trackArtists ?? [artist],
      album: album,
      albumArtist: albumArtist ?? artist,
      year: year,
      trackNo: n,
      durationMs: 60000,
      genre: genre,
      language: language,
      languageDetected: languageDetected,
      coverKey: coverKey,
      addedAt: year,
    ),
];

/// Encoded key of an album written by [addAlbum].
String albumId(String album, String artist) =>
    albumKeyFor(album: album, albumArtist: artist, artists: [artist])!.encode();

/// Titles of the song tiles built, in order.
List<String> tileTitles(WidgetTester tester) => [
  for (final t in tester.widgetList<SongTile>(find.byType(SongTile)))
    t.info.title,
];

/// [text] inside the page header (the name the header shows once it is
/// scrolled out of sight, or a fixed title).
Finder inPageHeader(String text) =>
    find.descendant(of: find.byType(PageHeader), matching: find.text(text));

/// How many semantics nodes are a header labelled exactly [label]. Needs
/// `tester.ensureSemantics()` to be held.
int headerNodes(WidgetTester tester, String label) => find.semantics
    .byFlag(SemanticsFlag.isHeader)
    .evaluate()
    .where((n) => n.getSemanticsData().label == label)
    .length;
