import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/browse/custom_cover_index_providers.dart';
import 'package:kanaru/src/library/state/browse/detail_providers.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_controller.dart';
import 'package:kanaru/src/library/state/covers/cover_dialog_options.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/covers/cover_dialog.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/open_menu.dart';
import 'package:kanaru/src/library/ui/playlists/menu/playlist_menu_rows.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/icon_button_finders.dart';
import '../ui/menus/menu_fakes.dart';
import '../ui/menus/menu_pump.dart';
import 'cover_test_support.dart';

class _Paths implements AppPaths {
  _Paths(Directory root)
    : dataDir = Directory('${root.path}/data')..createSync(),
      cacheDir = Directory('${root.path}/cache')..createSync(),
      configDir = Directory('${root.path}/config')..createSync();
  @override
  final Directory dataDir;
  @override
  final Directory cacheDir;
  @override
  final Directory configDir;
}

/// Counts builds and disposals of the dialog's controller and options.
base class _Lifecycle extends ProviderObserver {
  final events = <String>[];

  String? _name(ProviderObserverContext c) {
    final from = c.provider.from;
    if (from == coverDialogControllerProvider) return 'controller';
    if (from == coverDialogOptionsProvider) return 'options';
    return null;
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    final n = _name(context);
    if (n != null) events.add('add $n');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    final n = _name(context);
    if (n != null) events.add('dispose $n');
  }
}

void main() {
  late Directory dir;
  late FakeCoverController cover;
  late FakePicker picker;
  late _Lifecycle life;
  late StreamController<PlaylistDetail?> detailFeed;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_dlg_life_');
    cover = FakeCoverController(dir);
    picker = FakePicker();
    life = _Lifecycle();
    detailFeed = StreamController<PlaylistDetail?>.broadcast();
  });
  tearDown(() {
    unawaited(detailFeed.close());
    dir.deleteSync(recursive: true);
  });

  PlaylistSummary summary() => PlaylistSummary(
    uid: 'pl',
    name: '10 bài lặp lại',
    description: '',
    isFavorites: false,
    trackCount: 2,
    durationMs: 1000,
    createdAt: 1,
    updatedAt: 1,
    autoCoverKeys: [coverKeyOf(1)],
  );

  PlaylistDetail detail() => PlaylistDetail(
    summary: summary(),
    entries: [
      PlaylistEntryView(
        uid: 'e1',
        info: track(1, album: 'Alpha', cover: coverKeyOf(1)),
      ),
      PlaylistEntryView(
        uid: 'e2',
        info: track(2, album: 'Beta', cover: coverKeyOf(2)),
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        observers: [life],
        overrides: [
          musicFoldersProvider.overrideWith((ref) => Stream.value(const [])),
          fileManagerProvider.overrideWithValue(FakeFileManager()),
          appPathsProvider.overrideWithValue(_Paths(dir)),
          customCoverControllerProvider.overrideWithValue(cover),
          imageFilePickerProvider.overrideWithValue(picker),
          playlistDetailProvider.overrideWith((ref, uid) async* {
            yield detail();
            yield* detailFeed.stream;
          }),
          albumDetailProvider.overrideWith(
            (ref, key) => Stream.value(
              AlbumSummary(
                key: key.encode(),
                title: key.encode(),
                artist: 'a',
                year: 2000,
                trackCount: 1,
                durationMs: 1,
                coverKey: coverKeyOf(1),
                addedAt: 1,
              ),
            ),
          ),
          customCoverIndexProvider.overrideWith(
            (ref, kind) => Stream.value(const <String>{}),
          ),
          customCoverFileProvider.overrideWith(
            (ref, item) => Stream.value(null),
          ),
          customCoverThumbProvider.overrideWith(
            (ref, item) => Stream.value(null),
          ),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: const Locale('vi'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openMenu(
                  context,
                  (container, env) async => MenuSpec(
                    header: playlistMenuHeader(
                      summary(),
                      AppLocalizations.of(context),
                      desktop: false,
                    ),
                    groups: const [],
                  ),
                ),
                child: const Text('menu'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('mobile sheet from the playlist menu: the controller and the '
      'options are built once across pick, other row, new data and save', (
    tester,
  ) async {
    const once = ['add options', 'add controller'];
    await pump(tester, const Size(390, 844));
    await tester.tap(find.text('menu'));
    await pumpMenu(tester);
    await tester.tap(byIconButton('Đổi ảnh playlist'));
    await flush(tester);
    expect(find.byType(CoverDialog), findsOneWidget);
    expect(life.events, once);

    final image = pickedFile(dir, '1000006052.png');
    cover.sizes[image.file.path] = (w: 1179, h: 2556);
    picker.next = image;
    await tester.tap(find.textContaining('Chọn ảnh'));
    await flush(tester);
    final pickedRow = find.widgetWithText(SelectionRow, '1000006052.png');
    expect(find.text('Từ máy · 1179 × 2556'), findsOneWidget);

    for (final other in ['Tự động', 'Alpha']) {
      await tester.tap(find.widgetWithText(SelectionRow, other));
      await flush(tester);
      expect(pickedRow, findsOneWidget, reason: 'after $other');
    }
    // The playlist and its covers change underneath: the dialog keeps its
    // snapshot.
    detailFeed.add(detail());
    await flush(tester);
    expect(pickedRow, findsOneWidget);
    expect(image.file.existsSync(), isTrue);
    expect(life.events, once);

    await tester.tap(pickedRow);
    await flush(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await flush(tester);
    final choice = cover.changes.single.choice as FileCover;
    expect(choice.image.path, image.file.path);
    // Closed: both go, and only now.
    expect(life.events.take(2), once);
    expect(
      life.events.skip(2),
      unorderedEquals(['dispose controller', 'dispose options']),
    );
  });
}
