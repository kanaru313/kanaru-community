import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/browse/library_empty_state.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

import '../browse/support/library_fixture.dart';
import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

/// Page of every kind at twice the text size in a narrow window: nothing may
/// overflow (a RenderFlex overflow is a test failure).
Widget Function(Widget) _scaled(double scale) =>
    (page) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: page,
      ),
    );

Future<LibraryHarness> _pump(
  WidgetTester tester,
  String location, {
  double width = 360,
  double scale = 2,
}) => pumpLibrary(
  tester,
  initial: location,
  width: width,
  height: 640,
  header: _scaled(scale),
);

Future<void> _songs(LibraryHarness h, WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await addLibraryTrack(
      h.db,
      source: h.sourceId,
      locator: 'Album $i/1.flac',
      title: 'A fairly long song title number $i for the row',
      artists: ['An artist with a long name $i'],
      album: 'A long album name $i',
      albumArtist: 'An artist with a long name $i',
      year: 2000 + i,
      trackNo: 1,
      durationMs: 120000,
    );
  }
  await h.settle(tester);
}

void main() {
  for (final width in [320.0, 360.0, 400.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'songs page: width ${width.toInt()} dp, text scale $scale has no overflow',
        (tester) async {
          final h = await _pump(
            tester,
            '/library/songs',
            width: width,
            scale: scale,
          );
          await _songs(h, tester);
          expect(find.textContaining('A fairly long song title'), findsWidgets);
          expect(tester.takeException(), isNull);
          await unmountApp(tester);
        },
      );
    }
  }

  testWidgets('albums grid at text scale 2', (tester) async {
    final h = await _pump(tester, '/library/albums');
    await _songs(h, tester);
    expect(find.textContaining('A long album name'), findsWidgets);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('albums list at text scale 2', (tester) async {
    final h = await _pump(tester, '/library/albums');
    await _songs(h, tester);
    await tester.tap(find.byTooltip('List'));
    await h.settle(tester, rounds: 1);
    expect(find.textContaining('A long album name'), findsWidgets);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('folders page at text scale 2', (tester) async {
    final h = await _pump(tester, '/library/folders');
    final folder = await h.addFolder(
      'Music',
      volume: const StorageVolume(
        root: '/home/u',
        kind: StorageVolumeKind.home,
      ),
      root: '/home/u/Music',
    );
    for (final name in ['A folder with a rather long name', 'Another one']) {
      await addLibraryTrack(
        h.db,
        source: folder.sourceId,
        locator: '$name/a.flac',
        title: 'a',
      );
    }
    await addLibraryTrack(
      h.db,
      source: folder.sourceId,
      locator: 'loose song with a long file name.flac',
    );
    await h.settle(tester, rounds: 4);
    expect(find.textContaining('A folder with a rather'), findsWidgets);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('a detail page at text scale 2', (tester) async {
    final h = await _pump(tester, '/library/songs');
    await addAlbum(
      h,
      'A long album name for the page',
      'An artist name',
      year: 2001,
    );
    await h.settle(tester);
    h.router.push(
      LibraryLocations.album(
        AlbumKey.decode(
          albumId('A long album name for the page', 'An artist name'),
        )!,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(find.textContaining('A long album name'), findsWidgets);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('the empty state scrolls in a short window at text scale 2', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(480, 320);
    addTearDown(tester.view.reset);
    await pumpLibrary(
      tester,
      initial: '/library/albums',
      width: 480,
      height: 320,
      header: _scaled(2),
    );
    expect(find.byType(LibraryEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
    final button = find.text('Choose music folders');
    expect(button, findsOneWidget);
    // The button is below the fold until the state is scrolled.
    expect(tester.getBottomLeft(button).dy, greaterThan(320));
    await tester.drag(find.byType(LibraryEmptyState), const Offset(0, -400));
    await tester.pump();
    final bottom = tester.getBottomLeft(button).dy;
    expect(bottom, lessThanOrEqualTo(320));
    await unmountApp(tester);
  });
}
