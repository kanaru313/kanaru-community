import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/collections/album_tile.dart';
import 'package:kanaru/src/library/ui/collections/artist_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

/// Enough albums and artists to scroll every list.
Future<LibraryHarness> _pump(WidgetTester tester, String location) async {
  final h = await pumpLibrary(tester, initial: location);
  for (var i = 0; i < 40; i++) {
    await addLibraryTrack(
      h.db,
      source: h.sourceId,
      locator: 'a$i/1.flac',
      title: 'Song $i',
      artists: ['Artist $i'],
      album: 'Album $i',
      albumArtist: 'Artist $i',
      year: 2000 + i,
      trackNo: 1,
      durationMs: 120000,
    );
  }
  await h.settle(tester);
  return h;
}

/// Scrolls the list so its first [tile] is cut by the top edge, hovers the
/// visible part and checks where the hover ink goes. Ink is painted by the
/// nearest [Material]; the test fails when that reaches above the scroll view
/// and so over the page header.
Future<void> _expectInkClipped(WidgetTester tester, Finder tile) async {
  final scrollable = find
      .ancestor(of: tile.first, matching: find.byType(Scrollable))
      .first;
  await tester.drag(scrollable, const Offset(0, -60));
  await tester.pumpAndSettle();
  final viewport = tester.getRect(scrollable);
  final first = tester.getRect(tile.first);
  expect(first.top, lessThan(viewport.top), reason: 'the tile is cut off');

  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(Offset(first.center.dx, viewport.top + 4));
  await tester.pumpAndSettle();

  final ink = Material.of(tester.element(tile.first)) as RenderBox;
  final area = ink.localToGlobal(Offset.zero) & ink.size;
  expect(
    area.top,
    greaterThanOrEqualTo(viewport.top),
    reason: 'ink must not reach above the scroll view',
  );
}

void main() {
  testWidgets('album grid hover stays inside the grid', (tester) async {
    await _pump(tester, '/library/albums');
    await _expectInkClipped(tester, find.byType(AlbumCard));
    await unmountApp(tester);
  });

  testWidgets('artist list hover stays inside the list', (tester) async {
    await _pump(tester, '/library/artists');
    await _expectInkClipped(tester, find.byType(ArtistTile));
    await unmountApp(tester);
  });
}
