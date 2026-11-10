import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/custom_covers_store.dart';
import 'package:kanaru/src/library/state/browse/custom_cover_index_providers.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/ui/browse/item_covers.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

/// A 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

final _zed = ArtistKey('zed').encode();

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  String initial = '/library/albums',
  List<Override> overrides = const [],
}) async {
  final h = await pumpLibrary(tester, initial: initial, overrides: overrides);
  await addAlbum(h, 'Blue', 'Zed', year: 2001, coverKey: 'aaaaaaaaaaaaaaaa');
  await addAlbum(h, 'Amber', 'Yan', year: 2010, coverKey: 'bbbbbbbbbbbbbbbb');
  await addAlbum(h, 'Coral', 'Xi', year: 1999);
  await h.settle(tester);
  return h;
}

/// Gives the album or artist [itemKey] a custom cover, as the picker will.
Future<void> _choose(
  WidgetTester tester,
  LibraryHarness h,
  CustomCoverKind kind,
  String itemKey,
) async {
  final dir = h.container.read(appPathsProvider).dataDir;
  final src = File('${dir.path}/pick.png')..writeAsBytesSync(_png);
  await tester.runAsync(
    () => h.container
        .read(customCoverControllerProvider)
        .importCover(kind, itemKey, src),
  );
  await h.settle(tester, rounds: 4);
}

Future<void> _remove(
  WidgetTester tester,
  LibraryHarness h,
  CustomCoverKind kind,
  String itemKey,
) async {
  // Not in runAsync: the database waits on the lists' reloads, which run in
  // the test's fake time; settle lets both move.
  final done = h.container
      .read(customCoverControllerProvider)
      .removeCover(kind, itemKey);
  var finished = false;
  unawaited(done.whenComplete(() => finished = true));
  for (var i = 0; i < 20 && !finished; i++) {
    await h.settle(tester, rounds: 1);
  }
  await done;
  await h.settle(tester, rounds: 3);
}

/// Image of the [KCover] inside each [T] on screen, in order.
List<ImageProvider?> _images<T extends Widget>(WidgetTester tester) => [
  for (final c in tester.widgetList<T>(find.byType(T)))
    tester
        .widget<KCover>(
          find.descendant(of: find.byWidget(c), matching: find.byType(KCover)),
        )
        .image,
];

bool _isCustom(ImageProvider? image) =>
    image is FileImage && image.file.path.contains('custom_covers');

void main() {
  testWidgets('a custom cover replaces the source cover on an album card', (
    tester,
  ) async {
    final h = await _pump(tester);
    expect(_images<AlbumCover>(tester).where(_isCustom), isEmpty);
    await _choose(tester, h, CustomCoverKind.album, albumId('Blue', 'Zed'));
    final images = _images<AlbumCover>(tester);
    expect(images.where(_isCustom), hasLength(1));
    // Albums come newest first: Amber, Blue, Coral. Blue is the second.
    expect(_isCustom(images[1]), isTrue);
    expect(_isCustom(images[0]), isFalse);
    await unmountApp(tester);
  });

  testWidgets('removing the custom cover falls back to the source cover', (
    tester,
  ) async {
    final h = await _pump(tester);
    final id = albumId('Blue', 'Zed');
    await _choose(tester, h, CustomCoverKind.album, id);
    expect(_images<AlbumCover>(tester).where(_isCustom), hasLength(1));
    await _remove(tester, h, CustomCoverKind.album, id);
    expect(_images<AlbumCover>(tester).where(_isCustom), isEmpty);
    await unmountApp(tester);
  });

  testWidgets('a custom cover shows on an album row too', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byTooltip('List'));
    await h.settle(tester, rounds: 1);
    await _choose(tester, h, CustomCoverKind.album, albumId('Coral', 'Xi'));
    expect(_images<AlbumCover>(tester).where(_isCustom), hasLength(1));
    await unmountApp(tester);
  });

  testWidgets('an artist cover is the chosen photo, round', (tester) async {
    final h = await _pump(tester, initial: '/library/artists');
    expect(_images<ArtistCover>(tester).where(_isCustom), isEmpty);
    await _choose(tester, h, CustomCoverKind.artist, _zed);
    expect(_images<ArtistCover>(tester).where(_isCustom), hasLength(1));
    final round = tester
        .widgetList<KCover>(
          find.descendant(
            of: find.byType(ArtistCover),
            matching: find.byType(KCover),
          ),
        )
        .where((k) => _isCustom(k.image));
    expect(round.single.circle, isTrue);
    await unmountApp(tester);
  });

  testWidgets('the album page header shows the custom cover', (tester) async {
    final h = await _pump(tester, initial: '/library/songs');
    final id = albumId('Blue', 'Zed');
    h.router.push(LibraryLocations.album(AlbumKey.decode(id)!));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(_images<AlbumCover>(tester).where(_isCustom), isEmpty);
    await _choose(tester, h, CustomCoverKind.album, id);
    expect(_images<AlbumCover>(tester).where(_isCustom), hasLength(1));
    await _remove(tester, h, CustomCoverKind.album, id);
    expect(_images<AlbumCover>(tester).where(_isCustom), isEmpty);
    await unmountApp(tester);
  });

  testWidgets('the artist page header shows the custom photo', (tester) async {
    final h = await _pump(tester, initial: '/library/songs');
    h.router.push(LibraryLocations.artist(ArtistKey('zed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    await _choose(tester, h, CustomCoverKind.artist, _zed);
    expect(_images<ArtistCover>(tester).where(_isCustom), hasLength(1));
    await unmountApp(tester);
  });

  testWidgets('a grid of albums opens no file stream per tile', (tester) async {
    final built = <CustomCoverItem>[];
    final h = await _pump(
      tester,
      overrides: [
        customCoverFileProvider.overrideWith((ref, item) {
          built.add(item);
          return Stream.value(null);
        }),
      ],
    );
    expect(built, isEmpty);
    await _choose(tester, h, CustomCoverKind.album, albumId('Blue', 'Zed'));
    // Only the one album that has a custom cover opens its file stream.
    expect(built.map((i) => i.itemKey).toSet(), {albumId('Blue', 'Zed')});
    // The three tiles share one index stream per kind.
    expect(
      h.container.read(customCoverIndexProvider(CustomCoverKind.album).exists),
      isTrue,
    );
    expect(
      h.container.read(customCoverIndexProvider(CustomCoverKind.artist).exists),
      isFalse,
    );
    await unmountApp(tester);
  });

  testWidgets('a row whose file is gone keeps the source cover', (
    tester,
  ) async {
    final h = await _pump(tester);
    // A restored backup: the row is there, the image is not.
    await setCustomCover(h.db, 'album', albumId('Blue', 'Zed'), 'c' * 64);
    await h.settle(tester, rounds: 4);
    expect(_images<AlbumCover>(tester).where(_isCustom), isEmpty);
    expect(find.byType(AlbumCover), findsNWidgets(3));
    await unmountApp(tester);
  });

  testWidgets('a file that is not a valid image shows the source cover', (
    tester,
  ) async {
    final h = await _pump(tester);
    final hash = 'd' * 64;
    final dir = h.container.read(appPathsProvider).dataDir;
    final folder = Directory('${dir.path}/custom_covers')
      ..createSync(recursive: true);
    File('${folder.path}/$hash.png').writeAsBytesSync([1, 2, 3, 4]);
    final blueKey = albumId('Blue', 'Zed');
    await setCustomCover(h.db, 'album', blueKey, hash);
    await h.settle(tester, rounds: 4);
    final blue = find.byWidgetPredicate(
      (w) => w is AlbumCover && w.itemKey == blueKey,
    );
    final blueSource = find.descendant(
      of: blue,
      matching: find.byType(TrackCover),
    );
    final blueFile = find.descendant(of: blue, matching: find.byType(KCover));
    expect(blueFile, findsOneWidget);
    expect(_isCustom(tester.widget<KCover>(blueFile).image), isTrue);
    // The decode fails in real time: poll until the error frame shows the
    // source cover inside Blue's tile (bounded).
    for (var i = 0; i < 80 && blueSource.evaluate().isEmpty; i++) {
      await h.settle(tester, rounds: 1);
    }
    expect(blueSource, findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('one change rebuilds only the tile it concerns', (tester) async {
    final h = await _pump(tester);
    final blue = albumId('Blue', 'Zed');
    final amber = albumId('Amber', 'Yan');
    var blueFlips = 0;
    var amberFlips = 0;
    final subs = [
      h.container.listen(
        hasCustomCoverProvider((kind: CustomCoverKind.album, itemKey: blue)),
        (_, _) => blueFlips++,
      ),
      h.container.listen(
        hasCustomCoverProvider((kind: CustomCoverKind.album, itemKey: amber)),
        (_, _) => amberFlips++,
      ),
    ];
    addTearDown(() {
      for (final s in subs) {
        s.close();
      }
    });
    await _choose(tester, h, CustomCoverKind.album, blue);
    expect(blueFlips, 1);
    expect(amberFlips, 0);
    await unmountApp(tester);
  });

  testWidgets('the index ignores writes that leave its set unchanged', (
    tester,
  ) async {
    final h = await _pump(tester);
    final index = customCoverIndexProvider(CustomCoverKind.album);
    var emissions = 0;
    final sub = h.container.listen(index, (_, _) => emissions++);
    addTearDown(sub.close);
    await h.settle(tester, rounds: 2);
    final before = emissions;
    // An artist row touches the table, but not the album set.
    await setCustomCover(h.db, 'artist', _zed, 'd' * 64);
    await h.settle(tester, rounds: 4);
    expect(emissions, before);
    await unmountApp(tester);
  });
}
