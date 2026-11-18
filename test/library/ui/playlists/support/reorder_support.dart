import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:material_ui/material_ui.dart';

import 'playlist_page_support.dart';
import 'playlist_ui_harness.dart';

/// The row of [title].
Finder tileOf(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SongTile));

/// The drag handle of the row of [title], found by its semantics label
/// (nothing at all outside edit mode).
Finder handleOf(String title, String label) => find.descendant(
  of: tileOf(title),
  matching: find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == label,
    description: 'handle "$label"',
  ),
);

/// Every handle on screen, by semantics label.
Finder anyHandle(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
  description: 'any handle "$label"',
);

/// Presses the handle of [title] and moves it [rows] rows down (negative:
/// up), in steps; the pointer stays down.
Future<TestGesture> dragHandle(
  WidgetTester t,
  String title,
  String label,
  double rows,
) async {
  final gesture = await t.startGesture(t.getCenter(handleOf(title, label)));
  final extent = t.getSize(tileOf(title).first).height;
  await t.pump(const Duration(milliseconds: 50));
  const steps = 6;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, rows * extent / steps));
    await t.pump(const Duration(milliseconds: 16));
  }
  return gesture;
}

/// Releases [gesture] and lets the drop animation and what follows run.
Future<void> release(WidgetTester t, TestGesture gesture) async {
  await gesture.up();
  await t.pump(const Duration(milliseconds: 300));
}

/// Titles of playlist [uid]'s live entries in the order the database holds
/// them (titles taken from the entries the page shows).
Future<List<String>> storedOrder(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid,
) async {
  final live = (await t.runAsync(() => h.fixture.live(uid)))!;
  final names = {
    for (final e in shownDetail(h, uid)!.entries) e.uid: e.info.title,
  };
  return [for (final e in live) names[e.uid]!];
}

/// Waits (bounded, real time) until the stored order is [expected]; fails
/// with what it last found.
Future<void> expectStoredOrder(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid,
  List<String> expected,
) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  var found = await storedOrder(t, h, uid);
  while (found.join(',') != expected.join(',') &&
      DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
    found = await storedOrder(t, h, uid);
  }
  expect(found, expected, reason: 'the order in the database');
}
