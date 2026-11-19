// Self-check screenshots of the "Ảnh bìa" dialog on Linux desktop (1400x900).
//
// Run (from the main checkout, through main-build.sh):
//   flutter test integration_test/cover_dialog_test.dart -d linux
//
// Not part of CI: `tool/check` runs `flutter test` on `test/` (and the
// packages) only, so this folder is never collected; it needs a display.
// Screenshots go to $COVER_SHOTS_DIR (default: the plan's reports folder).
//
// The dialog runs on the real widgets with a fake store, picker and options
// source (as test/library/covers does); there is no database. Covers are
// generated PNGs, so thumbnails are placeholders of solid gradients.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
import 'package:kanaru/src/library/domain/covers/cover_preview.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/library/ui/covers/cover_dialog.dart';
import 'package:kanaru/src/library/ui/menus/album_menu.dart';
import 'package:kanaru/src/library/ui/menus/artist_menu.dart';
import 'package:kanaru/src/library/ui/menus/menu_header.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/library/ui/menus/open_menu.dart';
import 'package:kanaru/src/library/ui/playlists/menu/playlist_menu_spec.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/domain/image_file_picker.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../test/library/covers/cover_test_support.dart';
import '../test/library/ui/menus/menu_fakes.dart';
import '../test/library/ui/menus/menu_fixtures.dart' as fx;
import '../test/support/icon_button_finders.dart';

final _outDir =
    Platform.environment['COVER_SHOTS_DIR'] ??
    '/home/hieunm/dev/apps/kanaru/plans/261118-1810-custom-cover-dialog/reports';

/// A store whose previews are real images (the shared fake writes one byte).
class _RealPreviewController extends FakeCoverController {
  _RealPreviewController(super.dir);

  @override
  Future<CoverPreview> previewCover(File source) async {
    await previewGate?.future;
    if (previewError != null) throw previewError!;
    final file = File('${dir.path}/preview-${previews.length}.png')
      ..writeAsBytesSync(source.readAsBytesSync());
    previews.add(file);
    final size = sizes[source.path] ?? (w: 900, h: 1200);
    return CoverPreview(file: file, width: size.w, height: size.h);
  }
}

/// Writes a [w] x [h] gradient PNG tinted by [hue] to [file].
Future<File> _png(File file, int w, int h, double hue) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final a = HSVColor.fromAHSV(1, hue, .55, .85).toColor();
  final b = HSVColor.fromAHSV(1, (hue + 50) % 360, .7, .45).toColor();
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w.toDouble(), h.toDouble()),
        [a, b],
      ),
  );
  canvas.drawCircle(
    Offset(w / 2, h / 2),
    w / 4,
    Paint()..color = const Color(0x55FFFFFF),
  );
  final img = await rec.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  await file.writeAsBytes(data!.buffer.asUint8List());
  return file;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late _RealPreviewController cover;
  late FakePicker picker;
  final boundary = GlobalKey();
  // 'ok' | 'loading' | 'error': what the options source does.
  var mode = 'ok';
  var suggestionCount = 0;
  Completer<void>? optionsGate;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.pumpAndSettle();
  }

  /// [animated]: the screen never settles (spinner, skeleton), so it only
  /// pumps a fixed time instead of waiting for the frames to stop.
  Future<void> shot(
    WidgetTester tester,
    String state, {
    bool animated = false,
  }) async {
    if (animated) {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await tester.pump(const Duration(milliseconds: 120));
      }
    } else {
      await settle(tester);
      // Earlier steps scrolled the dialog; every shot starts at its top.
      final scroll = find.descendant(
        of: find.byType(CoverDialog),
        matching: find.byType(Scrollable),
      );
      if (scroll.evaluate().isNotEmpty) {
        tester.state<ScrollableState>(scroll.first).position.jumpTo(0);
        await settle(tester);
      }
    }
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await render.toImage();
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_outDir/screens-261119b-cover-$state-desktop.png');
    await file.writeAsBytes(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('shot ${file.path} ${img.width}x${img.height}');
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('kanaru_cover_it_');
    cover = _RealPreviewController(dir);
    picker = FakePicker();
    mode = 'ok';
    optionsGate = null;
    suggestionCount = 0;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<CoverSuggestion> suggestion(int i) async {
    final f = await _png(File('${dir.path}/s$i.png'), 200, 200, i * 47.0 % 360);
    return CoverSuggestion(
      albumKey: 'album$i',
      title: 'Album ${i + 1}',
      year: 1990 + i,
      thumb: f,
      full: f,
    );
  }

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext context;
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final suggestions = [
      for (var i = 0; i < suggestionCount; i++) await suggestion(i),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicFoldersProvider.overrideWith((ref) => Stream.value(const [])),
          fileManagerProvider.overrideWithValue(FakeFileManager()),
          coverDialogOptionsProvider.overrideWith((ref, item) async {
            if (mode == 'loading') await optionsGate!.future;
            if (mode == 'error') throw StateError('load failed');
            return CoverDialogOptions(
              itemName: switch (item.kind) {
                CustomCoverKind.album => 'Blue',
                CustomCoverKind.artist => 'Miles',
                CustomCoverKind.playlist => 'Mix cuối tuần',
              },
              automaticCoverKeys: const [],
              current: null,
              suggestions: suggestions,
            );
          }),
          customCoverControllerProvider.overrideWithValue(cover),
          imageFilePickerProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('vi'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (c, child) => RepaintBoundary(key: boundary, child: child),
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

  final vi = AppLocalizationsVi();
  MenuEnv env() => MenuEnv(l10n: vi, canReveal: true, pathOf: (_) => null);

  MenuSpec albumSpec() => buildAlbumMenu(
    AlbumMenuData(
      album: fx.albumSummary('Blue', 'Miles'),
      key: fx.albumKeyOf('Blue', 'Miles'),
      ids: fx.trackIds(3),
      folders: const [],
    ),
    const MenuOrigin.list(),
    env(),
  );

  MenuSpec artistSpec() => buildArtistMenu(
    ArtistMenuData(
      artist: const ArtistSummary(
        key: 'k',
        name: 'Miles',
        trackCount: 9,
        albumCount: 3,
        durationMs: 1000000,
        coverKey: null,
      ),
      key: ArtistKey(groupKey('Miles')),
      albums: ArtistAlbums(
        own: [fx.albumSummary('Blue', 'Miles')],
        appears: const [],
      ),
      ids: fx.trackIds(9),
      folders: const [],
    ),
    const MenuOrigin.list(),
    env(),
  );

  MenuSpec playlistSpec() => buildPlaylistMenu(
    PlaylistDetail(
      summary: PlaylistSummary(
        uid: 'pl',
        name: 'Mix cuối tuần',
        description: '',
        isFavorites: false,
        trackCount: 24,
        durationMs: 5400000,
        createdAt: 0,
        updatedAt: 0,
        autoCoverKeys: const [],
      ),
      entries: const [],
    ),
    env(),
    onOwnPage: false,
    desktop: true,
  );

  /// Opens [spec]'s menu and taps its cover button ([tooltip]).
  Future<void> openFromMenu(
    WidgetTester tester,
    MenuSpec spec,
    String tooltip,
  ) async {
    final context = await pumpHost(tester);
    unawaited(openMenu(context, (container, env) async => spec));
    await settle(tester);
    expect(find.byType(MenuHeaderView), findsOneWidget);
    await tester.tap(byIconButton(tooltip));
    await settle(tester);
  }

  final dialogScroll = find
      .descendant(
        of: find.byType(CoverDialog),
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> tapRow(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200, scrollable: dialogScroll);
    await tester.tap(f);
    await settle(tester);
  }

  Future<void> pick(
    WidgetTester tester, {
    required int w,
    required int h,
  }) async {
    final f = await _png(File('${dir.path}/pick-$w.png'), w, h, 200);
    cover.sizes[f.path] = (w: w, h: h);
    picker.next = PickedImage(file: f, name: 'IMG_2041.png', temporary: true);
    await tapRow(tester, find.textContaining('Chọn ảnh').first);
  }

  testWidgets('album', (tester) async {
    await openFromMenu(tester, albumSpec(), vi.coverEditAlbumTooltip);
    await shot(tester, 'album-normal');
    await tester.tap(find.widgetWithText(TextButton, 'Huỷ'));
    await settle(tester);
    expect(find.byType(CoverDialog), findsNothing);
    await shot(tester, 'album-menu-after-cancel');
  });

  testWidgets('artist', (tester) async {
    suggestionCount = 3;
    await openFromMenu(tester, artistSpec(), vi.coverEditArtistTooltip);
    await shot(tester, 'artist-normal');
    await tapRow(tester, find.text('Album 2'));
    await shot(tester, 'artist-suggestion-selected');
    await pick(tester, w: 900, h: 1200);
    await shot(tester, 'artist-picked-portrait');
  });

  testWidgets('playlist', (tester) async {
    suggestionCount = 9;
    await openFromMenu(tester, playlistSpec(), vi.playlistMenuChangeCover);
    await shot(tester, 'playlist-normal');
    await tapRow(tester, find.text('Album 2'));
    await shot(tester, 'playlist-suggestion-selected');
    await tapRow(tester, find.textContaining('Xem thêm'));
    await shot(tester, 'playlist-xem-them-expanded');
    await pick(tester, w: 900, h: 1200);
    await shot(tester, 'playlist-picked-portrait');
    await pick(tester, w: 400, h: 600);
    await shot(tester, 'playlist-small-image-warning');
    // Saving: the store holds the write until released.
    cover.gate = Completer<void>();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, 'playlist-saving', animated: true);
    cover.gate!.complete();
    await settle(tester);
  });

  testWidgets('playlist loading', (tester) async {
    mode = 'loading';
    optionsGate = Completer<void>();
    await openFromMenu(tester, playlistSpec(), vi.playlistMenuChangeCover);
    await shot(tester, 'playlist-loading', animated: true);
    optionsGate!.complete();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('playlist load error', (tester) async {
    mode = 'error';
    await openFromMenu(tester, playlistSpec(), vi.playlistMenuChangeCover);
    await shot(tester, 'playlist-load-error');
  });
}
