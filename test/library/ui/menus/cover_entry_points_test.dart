import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/browse/browse_items.dart';
import 'package:kanaru/src/library/domain/browse/menu_targets.dart';
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
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/platform/state/image_file_picker_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../../covers/cover_test_support.dart';
import 'menu_fakes.dart';
import 'menu_fixtures.dart';
import 'menu_pump.dart';

/// The header button of an album or artist menu opens the cover dialog over
/// the menu (the menu stays open underneath).
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('kanaru_entry_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext context;
    tester.view.physicalSize = const Size(900, 1000);
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
          customCoverControllerProvider.overrideWithValue(
            FakeCoverController(dir),
          ),
          imageFilePickerProvider.overrideWithValue(FakePicker()),
        ],
        child: MaterialApp(
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

  Future<void> tapHeaderButton(
    WidgetTester tester,
    MenuSpec spec,
    String tooltip,
  ) async {
    final context = await pumpHost(tester);
    unawaited(openMenu(context, (container, env) async => spec));
    await pumpMenu(tester);
    expect(find.byType(MenuHeaderView), findsOneWidget);
    await tester.tap(byIconButton(tooltip));
    await pumpMenu(tester);
    expect(find.byType(MenuHeaderView), findsOneWidget);
    expect(find.byType(CoverDialog), findsOneWidget);
  }

  testWidgets('album menu button opens the cover dialog', (tester) async {
    final spec = buildAlbumMenu(
      AlbumMenuData(
        album: albumSummary('Blue', 'Miles'),
        key: albumKeyOf('Blue', 'Miles'),
        ids: trackIds(3),
        folders: const [],
      ),
      const MenuOrigin.list(),
      env(),
    );
    await tapHeaderButton(tester, spec, 'Edit album cover');
  });

  testWidgets('artist menu button opens the cover dialog', (tester) async {
    final spec = buildArtistMenu(
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
    await tapHeaderButton(tester, spec, 'Set artist image');
  });
}
