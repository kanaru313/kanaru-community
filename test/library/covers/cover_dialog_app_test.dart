import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/covers/cover_dialog.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/menus/menu_header.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../database/support/test_db.dart';
import '../../support/app_harness.dart';
import '../../support/icon_button_finders.dart';
import 'cover_test_support.dart';

/// Lets the database answer (real time) and the routes animate (fake time).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }
  await tester.pumpAndSettle();
}

/// Closes the app, then runs out the custom cover files' keep-alive timers.
Future<void> _closeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

/// The cover dialog inside the whole app: router, shells, the real menus and
/// the real options of the item (only the image store and the picker are
/// fakes).
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('kanaru_cover_app_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> seedArtist(WidgetTester tester, ProviderContainer c) async {
    final db = c.read(appDatabaseProvider);
    await tester.runAsync(() async {
      final source = await addSource(db, uid: 'src-artist');
      for (final name in ['One', 'Two']) {
        final id = await addTrack(
          db,
          source,
          locator: '$name.flac',
          title: name,
        );
        await db
            .into(db.trackArtists)
            .insert(
              TrackArtistsCompanion.insert(
                trackId: id,
                artistKey: groupKey('164'),
                artistName: '164',
                position: 0,
              ),
            );
      }
    });
  }

  // 1000 wide is the mobile shell on a desktop window: the menu is a sheet,
  // the cover dialog a centred dialog.
  for (final width in [1400.0, 1000.0]) {
    for (final how in ['outside click', 'Esc']) {
      testWidgets('$width wide, artist page: the cover dialog opens over '
          'the menu; $how closes only the dialog', (tester) async {
        final c = await pumpKanaruApp(
          tester,
          width: width,
          height: 900,
          overrides: [
            customCoverControllerProvider.overrideWithValue(
              FakeCoverController(dir),
            ),
            imageFilePickerProvider.overrideWithValue(FakePicker()),
          ],
        );
        await seedArtist(tester, c);
        final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
        router.go(LibraryLocations.artist(ArtistKey(groupKey('164'))));
        await _settle(tester);
        final page = router.routerDelegate.currentConfiguration.uri.path;

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        Future<void> click(Offset at) async {
          await mouse.moveTo(at);
          // Hovered long enough for the tooltip, as a real pointer is.
          await tester.pump(const Duration(seconds: 2));
          await mouse.down(at);
          await tester.pump();
          await mouse.up();
        }

        await click(tester.getCenter(byAnyIconButton('More options').first));
        await _settle(tester);
        expect(find.byType(MenuHeaderView), findsOneWidget);
        await click(tester.getCenter(byAnyIconButton('Set artist image')));
        await _settle(tester);
        expect(find.byType(CoverDialog), findsOneWidget);
        expect(find.byType(MenuHeaderView), findsOneWidget);

        if (how == 'Esc') {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        } else {
          await click(const Offset(30, 450));
        }
        await _settle(tester);
        expect(find.byType(CoverDialog), findsNothing);
        expect(find.byType(MenuHeaderView), findsOneWidget);
        expect(router.routerDelegate.currentConfiguration.uri.path, page);
        // The menu still works: its cover button opens the dialog again.
        await click(tester.getCenter(byAnyIconButton('Set artist image')));
        await _settle(tester);
        expect(find.byType(CoverDialog), findsOneWidget);
        await _closeApp(tester);
      });
    }
  }

  // A successful Lưu closes the dialog and the menu under it. 390 is the
  // phone sheet, 1400 the desktop dialog.
  for (final width in [1400.0, 390.0]) {
    testWidgets('$width wide, artist page: Save closes the cover dialog and '
        'the menu', (tester) async {
      final cover = FakeCoverController(dir);
      final picker = FakePicker();
      final c = await pumpKanaruApp(
        tester,
        width: width,
        height: 900,
        overrides: [
          customCoverControllerProvider.overrideWithValue(cover),
          imageFilePickerProvider.overrideWithValue(picker),
        ],
      );
      await seedArtist(tester, c);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.go(LibraryLocations.artist(ArtistKey(groupKey('164'))));
      await _settle(tester);
      final page = router.routerDelegate.currentConfiguration.uri.path;

      await tester.tap(byAnyIconButton('More options').first);
      await _settle(tester);
      await tester.tap(byAnyIconButton('Set artist image'));
      await _settle(tester);
      expect(find.byType(CoverDialog), findsOneWidget);
      expect(find.byType(MenuHeaderView), findsOneWidget);

      picker.next = pickedFile(dir, 'artist.png');
      await tester.tap(find.textContaining('Choose image'));
      await tester.pump();
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await _settle(tester);

      expect(cover.changes, hasLength(1));
      expect(find.byType(CoverDialog), findsNothing);
      expect(find.byType(MenuHeaderView), findsNothing);
      expect(router.routerDelegate.currentConfiguration.uri.path, page);
      await _closeApp(tester);
    });
  }

  testWidgets('phone, playlist menu: a pick made while the app went to the '
      'background stays when another row is chosen', (tester) async {
    final cover = FakeCoverController(dir);
    final picker = FakePicker();
    final c = await pumpKanaruApp(
      tester,
      width: 390,
      height: 844,
      overrides: [
        customCoverControllerProvider.overrideWithValue(cover),
        imageFilePickerProvider.overrideWithValue(picker),
      ],
    );
    // The test phone: 1080 x 2400 px at 2.75.
    tester.view
      ..devicePixelRatio = 2.75
      ..physicalSize = const Size(1080, 2400);
    late String uid;
    final db = c.read(appDatabaseProvider);
    await tester.runAsync(() async {
      final source = await addSource(db, uid: 'src-pl');
      final id = await addTrack(db, source, locator: 'a.flac', title: 'A');
      uid = await c
          .read(playlistStoreProvider)
          .createPlaylist(
            name: '10 bai lap lai',
            tracks: [for (var i = 0; i < 10; i++) TrackId(id)],
          );
    });
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(LibraryLocations.playlist(uid));
    await _settle(tester);
    await tester.tap(byAnyIconButton('More options').first);
    await _settle(tester);
    await tester.tap(byAnyIconButton('Change playlist image'));
    await _settle(tester);
    expect(find.byType(CoverDialog), findsOneWidget);

    // The system photo picker covers the app: it goes to the background and
    // comes back with the image.
    final image = pickedFile(dir, '1000006052.png');
    cover.sizes[image.file.path] = (w: 1179, h: 2556);
    picker
      ..next = image
      ..gate = Completer<void>();
    await tester.tap(find.text('Choose image…'));
    await tester.pump();
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
      await tester.pump();
    }
    picker.gate!.complete();
    await _settle(tester);
    final pickedRow = find.widgetWithText(SelectionRow, '1000006052.png');
    expect(pickedRow, findsOneWidget);
    expect(find.text('From device · 1179 × 2556'), findsOneWidget);

    await tester.tap(find.widgetWithText(SelectionRow, 'Automatic'));
    await _settle(tester);
    expect(pickedRow, findsOneWidget);
    expect(
      isSemantics(isEnabled: true).matches(tester.getSemantics(pickedRow), {}),
      isTrue,
    );
    expect(image.file.existsSync(), isTrue);
    await _closeApp(tester);
  });
}
