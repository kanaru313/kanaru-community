import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/library/ui/menus/menu_action_runner.dart';
import 'package:kanaru/src/library/ui/menus/menu_header.dart';
import 'package:kanaru/src/library/ui/menus/menu_loaders.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/menu_origin.dart';
import 'package:kanaru/src/library/ui/menus/open_menu.dart';
import 'package:kanaru/src/library/ui/menus/song_menu.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'menu_fakes.dart';
import '../../../support/icon_button_finders.dart';
import 'menu_fixtures.dart';
import 'menu_pump.dart';

MenuSpec _song({MenuOrigin origin = const MenuOrigin.list()}) => buildSongMenu(
  SongMenuData(
    info: trackInfo(),
    links: trackLinks(),
    file: songFile,
    favorite: false,
    selected: false,
  ),
  origin,
  env(),
);

MenuItemSpec _row(MenuItemId id) =>
    MenuItemSpec(id, icon: KIcons.close, title: 'row ${id.name}');

Widget _app(Widget child, {double width = 400}) => MaterialApp(
  theme: buildKanaruTheme(brightness: Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// Pumps an empty app with the providers a menu load needs; returns a
/// context under it.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        musicFoldersProvider.overrideWith((ref) => Stream.value(const [])),
        fileManagerProvider.overrideWithValue(FakeFileManager()),
      ],
      child: _app(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return context;
}

void main() {
  group('song menu page rows', () {
    test('defaults return the menu unchanged', () {
      final spec = _song();
      expect(identical(withSongPageRows(spec), spec), isTrue);
    });

    test('the page group sits right after the "Go to" group', () {
      final spec = _song();
      final extra = [_row(MenuItemId.playlistRemove)];
      final out = withSongPageRows(spec, playlistGroup: extra);
      expect(out.groups.length, spec.groups.length + 1);
      expect(out.groups[0], spec.groups[0]);
      expect(out.groups[1], extra);
      expect(out.groups.sublist(2), spec.groups.sublist(1));
      expect(out.queueIds, spec.queueIds);
    });

    test('favoriteRow false drops the heart row only', () {
      final spec = _song();
      final ids = [
        for (final g in spec.groups)
          for (final i in g) i.id,
      ];
      expect(ids, contains(MenuItemId.favorite));
      final out = withSongPageRows(spec, favoriteRow: false);
      final left = [
        for (final g in out.groups)
          for (final i in g) i.id,
      ];
      expect(left, isNot(contains(MenuItemId.favorite)));
      expect(left.length, ids.length - 1);
    });

    test('the origin travels in the spec', () {
      final spec = withSongPageRows(
        _song(origin: const MenuOrigin.playlist('p1')),
        favoriteRow: false,
      );
      expect(spec.origin, const MenuOrigin.playlist('p1'));
      expect(
        const MenuOrigin.playlist('p1'),
        isNot(const MenuOrigin.playlist('p2')),
      );
      expect(const MenuOrigin.playlist('p1'), const MenuOrigin.playlist('p1'));
    });
  });

  testWidgets('hint is a row description, never visible text', (tester) async {
    final handle = tester.ensureSemantics();
    final context = await _pumpHost(tester);
    unawaited(
      openMenu(
        context,
        (container, env) async => MenuSpec(
          header: const MenuHeader(image: MenuImage.folder, title: 'h'),
          groups: [
            [
              const MenuItemSpec(
                MenuItemId.playlistEdit,
                icon: KIcons.edit,
                title: 'Edit',
                hint: 'Explains the row',
              ),
            ],
          ],
        ),
      ),
    );
    await pumpMenu(tester);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Explains the row'), findsNothing);
    expect(tester.getSemantics(find.text('Edit')).hint, 'Explains the row');
    handle.dispose();
  });

  group('playlist header', () {
    testWidgets('one-line note and an action that runs', (tester) async {
      var ran = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            MenuHeaderView(
              header: MenuHeader(
                image: MenuImage.playlist,
                itemKey: 'favorites',
                title: 'Mix',
                subtitle: '3 songs',
                note: 'A long description ' * 20,
                action: MenuTrailingSpec(
                  icon: KIcons.imageEdit,
                  tooltip: 'Change cover',
                  action: MenuAction.run((_) async {}),
                ),
              ),
              onAction: () => ran++,
            ),
          ),
        ),
      );
      final note = tester.widget<Text>(
        find.textContaining('A long description'),
      );
      expect(note.maxLines, 1);
      expect(note.overflow, TextOverflow.ellipsis);
      final action = find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == 'Change cover',
      );
      await tester.tap(action);
      expect(ran, 1);
    });

    testWidgets('the action closes the menu, then runs once', (tester) async {
      var ran = 0;
      final context = await _pumpHost(tester);
      unawaited(
        openMenu(
          context,
          (container, env) async => MenuSpec(
            header: MenuHeader(
              image: MenuImage.folder,
              title: 'HeaderTitle',
              action: MenuTrailingSpec(
                icon: KIcons.imageEdit,
                tooltip: 'Change cover',
                action: MenuAction.run((_) async => ran++),
              ),
            ),
            groups: const [],
          ),
        ),
      );
      await pumpMenu(tester);
      expect(find.text('HeaderTitle'), findsOneWidget);
      await tester.tap(byIconButton('Change cover'));
      await pumpMenu(tester);
      expect(find.text('HeaderTitle'), findsNothing);
      expect(ran, 1);
    });

    testWidgets('no note and no action: only title and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            const MenuHeaderView(
              header: MenuHeader(
                image: MenuImage.playlist,
                itemKey: 'favorites',
                title: 'Mix',
                subtitle: 'Empty',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(KIconButton), findsNothing);
      expect(find.text('Mix'), findsOneWidget);
    });
  });

  testWidgets('a run action receives the root context and its failure is '
      'contained', (tester) async {
    BuildContext? got;
    late BuildContext root;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            root = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final runner = MenuActionRunner(container, root);
    await runner.run(
      MenuAction.run((context) async {
        got = context;
      }),
    );
    expect(got, same(root));

    await runner.run(MenuAction.run((_) async => throw StateError('boom')));
    await tester.pump();
    expect(find.text(l10n.libraryActionFailed), findsOneWidget);
    expect(find.text(l10n.libraryMenuLoadFailed), findsNothing);
  });

  testWidgets('openMenu: an item that is gone shows the not-found toast and '
      'no menu', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicFoldersProvider.overrideWith((ref) => Stream.value(const [])),
          fileManagerProvider.overrideWithValue(FakeFileManager()),
        ],
        child: _app(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await openMenu(
      context,
      (container, env) => throw const ItemGoneException('playlist p1'),
    );
    await tester.pump();
    expect(find.text(l10n.libraryNotFoundMessage), findsOneWidget);
    // No menu: neither a header nor a footer button of one is on screen.
    expect(find.text(l10n.libraryMenuPlayNext), findsNothing);
  });
}
