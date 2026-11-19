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
import 'package:kanaru/src/library/ui/menus/album_menu.dart';
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

/// The header button closes the menu before the cover dialog opens (the menu
/// contract: a chosen row closes the menu, then runs). So the dialog is the
/// only layer above the page, and one outside tap / Esc closes exactly it.
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

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kanaru_layers_');
    routes = _Routes();
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
          customCoverControllerProvider.overrideWithValue(
            FakeCoverController(dir),
          ),
          imageFilePickerProvider.overrideWithValue(FakePicker()),
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

  for (final (name, size) in [
    ('mobile sheet', const Size(900, 1000)),
    ('desktop dialog', const Size(1400, 900)),
  ]) {
    for (final close in ['outside tap', 'Esc', 'Cancel']) {
      testWidgets('$name: $close closes only the cover dialog; the menu '
          'is already gone', (tester) async {
        final context = await pumpHost(tester, size);
        final base = routes.live.length;
        unawaited(openMenu(context, (container, env) async => albumSpec()));
        await pumpMenu(tester);
        expect(routes.live.length, base + 1);
        await tester.tap(byIconButton('Edit album cover'));
        await pumpMenu(tester);
        // Menu closed first, dialog is the one layer above the page.
        expect(find.byType(MenuHeaderView), findsNothing);
        expect(find.byType(CoverDialog), findsOneWidget);
        expect(routes.live.length, base + 1);

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
        expect(find.byType(MenuHeaderView), findsNothing);
        expect(routes.live.length, base);
      });
    }
  }
}
