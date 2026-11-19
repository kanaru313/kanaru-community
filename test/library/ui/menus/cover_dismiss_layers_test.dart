import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/library/ui/covers/cover_dialog.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/menus/album_menu.dart';
import 'package:kanaru/src/library/ui/menus/artist_menu.dart';
import 'package:kanaru/src/library/ui/playlists/menu/playlist_menu_spec.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/library/ui/menus/menu_header.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/library/ui/menus/open_menu.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../../covers/cover_test_support.dart';
import 'menu_fakes.dart';
import 'menu_fixtures.dart';
import 'menu_pump.dart';

/// The header cover button opens the cover dialog OVER the menu (a
/// `MenuAction.runOver`): two layers above the page. One outside tap / Esc /
/// Cancel pops exactly the dialog, the menu is back and interactive; a
/// finished action (a saved cover) closes both.
class _Routes extends NavigatorObserver {
  final live = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previous) =>
      live.add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previous) =>
      live.remove(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previous) =>
      live.remove(route);
}

void main() {
  late Directory dir;
  late _Routes routes;
  late FakeCoverController cover;
  late FakePicker picker;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_layers_');
    routes = _Routes();
    cover = FakeCoverController(dir);
    picker = FakePicker();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<BuildContext> pumpHost(WidgetTester tester, Size size) async {
    late BuildContext context;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicFoldersProvider.overrideWith((ref) => Stream.value(const [])),
          fileManagerProvider.overrideWithValue(FakeFileManager()),
          coverDialogOptionsProvider.overrideWith(
            (ref, i) async => const CoverDialogOptions(
              itemName: 'Item',
              automaticCoverKeys: [],
              current: null,
              suggestions: [],
            ),
          ),
          customCoverControllerProvider.overrideWithValue(cover),
          imageFilePickerProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          navigatorObservers: [routes],
          theme: buildKanaruTheme(brightness: Brightness.light),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    return context;
  }

  MenuSpec albumSpec() => buildAlbumMenu(
    AlbumMenuData(
      album: albumSummary('Blue', 'Miles'),
      key: albumKeyOf('Blue', 'Miles'),
      ids: trackIds(3),
      folders: const [],
    ),
    const MenuOrigin.list(),
    env(),
  );

  MenuSpec artistSpec() => buildArtistMenu(
    ArtistMenuData(
      artist: const ArtistSummary(
        key: 'k',
        name: 'Vu',
        trackCount: 1,
        albumCount: 1,
        durationMs: 1000,
        coverKey: null,
      ),
      key: ArtistKey(groupKey('Vu')),
      albums: ArtistAlbums(own: [albumSummary('A', 'Vu')], appears: const []),
      ids: trackIds(1),
      folders: const [],
    ),
    const MenuOrigin.list(),
    env(),
  );

  MenuSpec playlistSpec() => buildPlaylistMenu(
    PlaylistDetail(
      summary: PlaylistSummary(
        uid: 'pl',
        name: 'Mix',
        description: '',
        isFavorites: false,
        trackCount: 0,
        durationMs: 0,
        createdAt: 0,
        updatedAt: 0,
        autoCoverKeys: const [],
      ),
      entries: const [],
    ),
    env(),
    onOwnPage: false,
    desktop: false,
  );

  final kinds = <(String, MenuSpec Function(), String)>[
    ('album', albumSpec, 'Edit album cover'),
    ('artist', artistSpec, 'Set artist image'),
    ('playlist', playlistSpec, 'Change playlist image'),
  ];

  for (final (name, size) in [
    ('mobile sheet', const Size(900, 1000)),
    ('desktop dialog', const Size(1400, 900)),
  ]) {
    for (final (kind, spec, tooltip) in kinds) {
      for (final close in ['outside tap', 'Esc', 'Cancel']) {
        testWidgets('$name $kind: $close pops only the cover dialog; the menu '
            'stays and works', (tester) async {
          final context = await pumpHost(tester, size);
          final base = routes.live.length;
          unawaited(openMenu(context, (container, env) async => spec()));
          await pumpMenu(tester);
          expect(routes.live.length, base + 1);
          await tester.tap(byIconButton(tooltip));
          await pumpMenu(tester);
          // The dialog opened over the menu: two layers above the page.
          expect(find.byType(MenuHeaderView), findsOneWidget);
          expect(find.byType(CoverDialog), findsOneWidget);
          expect(routes.live.length, base + 2);

          switch (close) {
            case 'outside tap':
              await tester.tapAt(const Offset(4, 4));
            case 'Esc':
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            default:
              await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
          }
          await pumpMenu(tester);
          expect(find.byType(CoverDialog), findsNothing);
          expect(find.byType(MenuHeaderView), findsOneWidget);
          expect(routes.live.length, base + 1);

          // Interactive: the button opens the dialog again.
          await tester.tap(byIconButton(tooltip));
          await pumpMenu(tester);
          expect(find.byType(CoverDialog), findsOneWidget);
          expect(routes.live.length, base + 2);
        });
      }
    }

    testWidgets('$name: Android Back pops only the cover dialog', (
      tester,
    ) async {
      final context = await pumpHost(tester, size);
      final base = routes.live.length;
      unawaited(openMenu(context, (container, env) async => albumSpec()));
      await pumpMenu(tester);
      await tester.tap(byIconButton('Edit album cover'));
      await pumpMenu(tester);
      expect(routes.live.length, base + 2);
      await tester.binding.handlePopRoute();
      await pumpMenu(tester);
      expect(find.byType(CoverDialog), findsNothing);
      expect(find.byType(MenuHeaderView), findsOneWidget);
      expect(routes.live.length, base + 1);
    });

    testWidgets('$name: a runOver action that throws leaves the menu open, '
        'toasts, and the button works again', (tester) async {
      final context = await pumpHost(tester, size);
      final base = routes.live.length;
      var calls = 0;
      unawaited(
        openMenu(
          context,
          (container, env) async => MenuSpec(
            header: MenuHeader(
              image: MenuImage.folder,
              title: 'HeaderTitle',
              action: MenuTrailingSpec(
                icon: KIcons.imageEdit,
                tooltip: 'Over',
                action: MenuAction.runOver((ctx) async {
                  calls++;
                  throw StateError('boom');
                }),
              ),
            ),
            groups: const [],
          ),
        ),
      );
      await pumpMenu(tester);
      await tester.tap(byIconButton('Over'));
      await pumpMenu(tester);
      expect(calls, 1);
      expect(find.text('HeaderTitle'), findsOneWidget);
      expect(routes.live.length, base + 1);
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(byIconButton('Over'));
      await pumpMenu(tester);
      expect(calls, 2, reason: 'the in-progress guard was reset');
    });

    testWidgets('$name: closing the dialog while Lưu runs never pops the '
        'menu, and the save still completes', (tester) async {
      final context = await pumpHost(tester, size);
      final base = routes.live.length;
      unawaited(openMenu(context, (container, env) async => albumSpec()));
      await pumpMenu(tester);
      await tester.tap(byIconButton('Edit album cover'));
      await pumpMenu(tester);
      final image = pickedFile(dir, 'pic.png');
      cover.sizes[image.file.path] = (w: 100, h: 100);
      picker.next = image;
      await tester.tap(find.textContaining('Choose image'));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await pumpMenu(tester);
      // The save waits on the gate; the user dismisses the dialog meanwhile.
      cover.gate = Completer<void>();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 40));
      // Finishes while the dialog is still animating out.
      cover.gate!.complete();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      await pumpMenu(tester);
      expect(cover.changes, hasLength(1), reason: 'the save went through');
      expect(find.byType(CoverDialog), findsNothing);
      expect(find.byType(MenuHeaderView), findsOneWidget);
      expect(routes.live.length, base + 1);
    });

    for (final done in [true, false]) {
      testWidgets('$name: a runOver action reporting $done '
          '${done ? "closes both layers" : "leaves the menu open"}', (
        tester,
      ) async {
        final context = await pumpHost(tester, size);
        final base = routes.live.length;
        var calls = 0;
        unawaited(
          openMenu(
            context,
            (container, env) async => MenuSpec(
              header: MenuHeader(
                image: MenuImage.folder,
                title: 'HeaderTitle',
                action: MenuTrailingSpec(
                  icon: KIcons.imageEdit,
                  tooltip: 'Over',
                  action: MenuAction.runOver((ctx) async {
                    calls++;
                    await showDialog<void>(
                      context: ctx,
                      useRootNavigator: true,
                      builder: (_) => const AlertDialog(content: Text('Dlg')),
                    );
                    return done;
                  }),
                ),
              ),
              groups: const [],
            ),
          ),
        );
        await pumpMenu(tester);
        await tester.tap(byIconButton('Over'));
        await pumpMenu(tester);
        expect(find.text('Dlg'), findsOneWidget);
        expect(find.text('HeaderTitle'), findsOneWidget);
        expect(routes.live.length, base + 2);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await pumpMenu(tester);
        expect(calls, 1);
        expect(find.text('Dlg'), findsNothing);
        expect(find.text('HeaderTitle'), done ? findsNothing : findsOneWidget);
        expect(routes.live.length, done ? base : base + 1);
      });
    }
  }
}
