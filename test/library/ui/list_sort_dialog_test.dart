import 'package:flutter/semantics.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_labels.dart';
import 'package:kanaru/src/library/ui/browse/list_sort_dialog.dart';
import 'package:kanaru/src/library/ui/browse/list_sort_popover.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/icon_button_finders.dart';
import '../../support/memory_settings_store.dart';
import '../browse/support/library_fixture.dart';
import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<void> _song(
  LibraryHarness h,
  String title, {
  String artist = 'Zed',
  int? year,
  String? album,
}) => addLibraryTrack(
  h.db,
  source: h.sourceId,
  locator: '$title-${album ?? artist}.flac',
  title: title,
  artists: [artist],
  year: year,
  album: album,
);

Future<LibraryHarness> _songsPage(
  WidgetTester tester, {
  List<Override> overrides = const [],
  MemorySettingsStore? settings,
  List<(String, String)> songs = const [('Ace', 'Yan'), ('Bee', 'Xia')],
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/songs',
    overrides: overrides,
    settings: settings,
  );
  for (final (title, artist) in songs) {
    await _song(h, title, artist: artist);
  }
  await h.settle(tester);
  return h;
}

SortOrder _songsSort(LibraryHarness h) =>
    h.container.read(libraryListViewsProvider).of(BrowseList.songs).sort;

Future<void> _setSongsSort(
  LibraryHarness h,
  WidgetTester tester,
  SortOrder sort,
) async {
  await h.container
      .read(libraryListViewsProvider.notifier)
      .setSort(BrowseList.songs, sort);
  await h.settle(tester);
}

/// Taps the sort chip (it shows [label]), then "Advanced…".
Future<void> _openDialog(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Advanced…'));
  await tester.pumpAndSettle();
}

/// Rows of the song list, top to bottom, by their album (unique per test row).
List<String> _albums(WidgetTester tester) => [
  for (final t in tester.widgetList<SongTile>(find.byType(SongTile)))
    t.info.album ?? '',
];

RegExp _rowLabel(String name, int n) => RegExp('^$n\\. $name(\\n|\$)');

void _perform(WidgetTester tester, String name, int n, String label) {
  final data = tester
      .getSemantics(find.bySemanticsLabel(_rowLabel(name, n)))
      .getSemanticsData();
  final id = {
    for (final id in data.customSemanticsActionIds ?? const <int>[])
      CustomSemanticsAction.getAction(id)!.label!: id,
  }[label]!;
  tester.semantics.performAction(
    find.semantics.byLabel(_rowLabel(name, n)),
    SemanticsAction.customAction,
    args: id,
  );
}

({AlbumKey key, String id}) _albumPage(String album, String artist) {
  final id = albumId(album, artist);
  return (key: AlbumKey.decode(id)!, id: id);
}

Future<(ProviderContainer, GlobalKey<_ToggleState>)> pumpHost(
  WidgetTester tester, {
  required bool guarded,
  ListSortGuard? guard,
  bool dropdown = false,
}) async {
  final container = ProviderContainer(
    overrides: [settingsStoreProvider.overrideWithValue(MemorySettingsStore())],
  );
  addTearDown(container.dispose);
  final key = GlobalKey<_ToggleState>();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: _Toggle(
            key: key,
            child: _Page(guarded: guarded, guard: guard),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text(dropdown ? 'sort' : 'open'));
  await tester.pumpAndSettle();
  expect(find.text(dropdown ? 'Advanced…' : 'Sort by'), findsOneWidget);
  return (container, key);
}

void main() {
  group('dropdown', () {
    testWidgets('a pick keeps the direction of the first criterion', (
      tester,
    ) async {
      final h = await _songsPage(tester);
      await _setSongsSort(
        h,
        tester,
        SortOrder.by(SortCriterion.title, descending: true),
      );
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Artist'));
      await tester.pumpAndSettle();
      expect(
        _songsSort(h),
        SortOrder.by(SortCriterion.artist, descending: true),
      );
      await unmountApp(tester);
    });

    testWidgets('a pick with three criteria leaves only that one', (
      tester,
    ) async {
      final h = await _songsPage(tester);
      await _setSongsSort(
        h,
        tester,
        SortOrder([
          const SortSpec(SortCriterion.title),
          const SortSpec(SortCriterion.artist, descending: true),
          const SortSpec(SortCriterion.year),
        ]),
      );
      expect(find.text('Name +2'), findsOneWidget);
      await tester.tap(find.text('Name +2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      expect(_songsSort(h), SortOrder.by(SortCriterion.year));
      expect(find.text('Year'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('Advanced… closes the dropdown and opens the box', (
      tester,
    ) async {
      await _songsPage(tester);
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advanced…'));
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsOneWidget);
      expect(find.text('Chosen'), findsOneWidget);
      expect(find.text('Not chosen'), findsOneWidget);
      expect(find.text('Advanced…'), findsNothing);
      await unmountApp(tester);
    });
  });

  group('box', () {
    testWidgets('adding Year appends it newest first and the chip counts it', (
      tester,
    ) async {
      final h = await _songsPage(tester);
      await _openDialog(tester, 'Name');
      await tester.tap(byIconButton('Add Year'));
      await tester.pumpAndSettle();
      expect(
        _songsSort(h),
        SortOrder([
          const SortSpec(SortCriterion.title),
          const SortSpec(SortCriterion.year, descending: true),
        ]),
      );
      expect(find.text('Name +1'), findsOneWidget);
      // The new row is in the box now.
      expect(byIconButton('Remove Year'), findsOneWidget);
      expect(byIconButton('Add Year'), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('direction words follow the kind of the criterion', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _songsPage(tester);
      await _openDialog(tester, 'Name');
      await tester.tap(byIconButton('Add Year'));
      await tester.pumpAndSettle();
      await tester.tap(byIconButton('Add Play count'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Name: A → Z, tap to switch direction'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Year: Newest first, tap to switch direction'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Play count: Ascending, tap to switch direction'),
        findsOneWidget,
      );
      expect(byIconButton('Switch direction: Oldest first'), findsOneWidget);
      await tester.tap(byIconButton('Switch direction: Oldest first'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Year: Oldest first, tap to switch direction'),
        findsOneWidget,
      );
      handle.dispose();
      await unmountApp(tester);
    });

    testWidgets('moving a row reorders the criteria and the list', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = await pumpLibrary(tester, initial: '/library/songs');
      for (final (title, artist) in [
        ('Bee', 'Xia'),
        ('Ace', 'Yan'),
        ('Cat', 'Xia'),
      ]) {
        await _song(h, title, artist: artist, album: 'in $title');
      }
      await h.settle(tester);
      await _setSongsSort(
        h,
        tester,
        SortOrder([
          const SortSpec(SortCriterion.title),
          const SortSpec(SortCriterion.artist),
        ]),
      );
      expect(_albums(tester), ['in Ace', 'in Bee', 'in Cat']);
      await _openDialog(tester, 'Name +1');
      _perform(tester, 'Name', 1, 'Move down');
      await tester.pumpAndSettle();
      await h.settle(tester);
      expect(
        _songsSort(h),
        SortOrder([
          const SortSpec(SortCriterion.artist),
          const SortSpec(SortCriterion.title),
        ]),
      );
      expect(find.text('Artist +1'), findsOneWidget);
      expect(_albums(tester), ['in Bee', 'in Cat', 'in Ace']);
      handle.dispose();
      await unmountApp(tester);
    });

    testWidgets('Reset goes back to the first criterion alone', (tester) async {
      final h = await _songsPage(tester);
      await _setSongsSort(
        h,
        tester,
        SortOrder([
          const SortSpec(SortCriterion.year, descending: true),
          const SortSpec(SortCriterion.artist),
        ]),
      );
      await _openDialog(tester, 'Year +1');
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(_songsSort(h), SortOrder.by(SortCriterion.title));
      // The rows follow: Year is offered again.
      expect(byIconButton('Add Year'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('a scan reload while the box is open keeps its rows', (
      tester,
    ) async {
      final h = await _songsPage(tester);
      await _setSongsSort(
        h,
        tester,
        SortOrder([
          const SortSpec(SortCriterion.title),
          const SortSpec(SortCriterion.artist),
        ]),
      );
      await _openDialog(tester, 'Name +1');
      await _song(h, 'Cat', artist: 'Zed');
      await h.settle(tester);
      expect(byIconButton('Remove Name'), findsOneWidget);
      expect(byIconButton('Remove Artist'), findsOneWidget);
      expect(byIconButton('Add Year'), findsOneWidget);
      expect(_songsSort(h).specs.length, 2);
      await unmountApp(tester);
    });

    testWidgets('Done closes it', (tester) async {
      await _songsPage(tester);
      await _openDialog(tester, 'Name');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing);
      await unmountApp(tester);
    });
  });

  group('remembering', () {
    testWidgets('a list page sort, Reverse included, outlives the container', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      final h = await _songsPage(tester, settings: store);
      await _openDialog(tester, 'Name');
      await tester.tap(byIconButton('Add Year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(byIconButton('Reverse order'));
      await h.settle(tester);
      final expected = SortOrder([
        const SortSpec(SortCriterion.title, descending: true),
        const SortSpec(SortCriterion.year),
      ]);
      expect(_songsSort(h), expected);
      final next = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(next.dispose);
      expect(
        next.read(libraryListViewsProvider).of(BrowseList.songs).sort,
        expected,
      );
      await unmountApp(tester);
    });

    group('detail page', () {
      late LibraryHarness h;
      late MemorySettingsStore store;
      final album = _albumPage('Blue', 'Zed');
      final page = (list: BrowseList.albumTracks, item: album.id);

      Future<void> open(WidgetTester tester) async {
        store = MemorySettingsStore();
        h = await pumpLibrary(
          tester,
          initial: '/library/songs',
          settings: store,
        );
        await addAlbum(h, 'Blue', 'Zed');
        await h.settle(tester);
        h.router.push(LibraryLocations.album(album.key));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await h.settle(tester);
      }

      SortOrder? override() =>
          h.container.read(detailSortOverridesProvider)[page];

      testWidgets('a change lives in the session only', (tester) async {
        await open(tester);
        await _openDialog(tester, 'Track number');
        await tester.tap(byIconButton('Add Name'));
        await tester.pumpAndSettle();
        expect(override()?.specs.length, 2);
        expect(find.text('Track number +1'), findsOneWidget);
        final next = ProviderContainer(
          overrides: [settingsStoreProvider.overrideWithValue(store)],
        );
        addTearDown(next.dispose);
        expect(next.read(detailSortOverridesProvider), isEmpty);
        expect(
          next.read(libraryListViewsProvider).of(BrowseList.albumTracks).sort,
          SortOrder.by(SortCriterion.trackNumber),
        );
        await unmountApp(tester);
      });

      testWidgets('Reset drops the override: the remembered sort of the kind', (
        tester,
      ) async {
        await open(tester);
        await h.container
            .read(libraryListViewsProvider.notifier)
            .setSort(
              BrowseList.albumTracks,
              SortOrder.by(SortCriterion.trackNumber, descending: true),
            );
        await h.container
            .read(detailSortOverridesProvider.notifier)
            .set(page, SortOrder.by(SortCriterion.title));
        await h.settle(tester);
        await _openDialog(tester, 'Name');
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        expect(override(), isNull);
        expect(
          h.container.read(detailSortProvider(page)),
          SortOrder.by(SortCriterion.trackNumber, descending: true),
        );
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.text('Track number'), findsOneWidget);
        await unmountApp(tester);
      });

      testWidgets('Track number is appended as the third criterion', (
        tester,
      ) async {
        await open(tester);
        await h.container
            .read(detailSortOverridesProvider.notifier)
            .set(
              page,
              SortOrder([
                const SortSpec(SortCriterion.title),
                const SortSpec(SortCriterion.duration),
              ]),
            );
        await h.settle(tester);
        await _openDialog(tester, 'Name +1');
        await tester.tap(byIconButton('Add Track number'));
        await tester.pumpAndSettle();
        expect(override()!.specs.map((s) => s.criterion), [
          SortCriterion.title,
          SortCriterion.duration,
          SortCriterion.trackNumber,
        ]);
        await unmountApp(tester);
      });

      testWidgets('two Reverse taps in one frame flip twice', (tester) async {
        await open(tester);
        final reverse = byIconButton('Reverse order');
        await tester.tap(reverse, warnIfMissed: false);
        await tester.tap(reverse, warnIfMissed: false);
        await tester.pump();
        expect(
          h.container.read(detailSortProvider(page)),
          SortOrder.by(SortCriterion.trackNumber),
        );
        await unmountApp(tester);
      });

      testWidgets('Reverse flips every criterion on the page only', (
        tester,
      ) async {
        await open(tester);
        await tester.tap(byIconButton('Reverse order'));
        await h.settle(tester);
        expect(
          override(),
          SortOrder.by(SortCriterion.trackNumber, descending: true),
        );
        expect(
          h.container
              .read(libraryListViewsProvider)
              .of(BrowseList.albumTracks)
              .sort,
          SortOrder.by(SortCriterion.trackNumber),
        );
        await unmountApp(tester);
      });
    });
  });

  group('Reverse order', () {
    testWidgets(
      'mirrors the rows, keeps equal ones in order, flips the arrow',
      (tester) async {
        final h = await pumpLibrary(tester, initial: '/library/songs');
        await _song(h, 'Ant', album: 'x1');
        await _song(h, 'Bob', artist: 'P', album: 'x2');
        await _song(h, 'Bob', artist: 'Q', album: 'x3');
        await h.settle(tester);
        expect(_albums(tester), ['x1', 'x2', 'x3']);
        KIconButton reverse() =>
            tester.widget<KIconButton>(byIconButton('Reverse order'));
        expect(reverse().icon, KIcons.sortAsc);
        await tester.tap(byIconButton('Reverse order'));
        await h.settle(tester);
        expect(
          _songsSort(h),
          SortOrder.by(SortCriterion.title, descending: true),
        );
        // The two Bob rows are equal on the key: they stay in their order.
        expect(_albums(tester), ['x2', 'x3', 'x1']);
        expect(reverse().icon, KIcons.sortDesc);
        await tester.tap(byIconButton('Reverse order'));
        await h.settle(tester);
        expect(_albums(tester), ['x1', 'x2', 'x3']);
        await unmountApp(tester);
      },
    );

    testWidgets('the direction buttons of the box follow it', (tester) async {
      final handle = tester.ensureSemantics();
      final h = await _songsPage(tester);
      await _openDialog(tester, 'Name');
      expect(
        find.bySemanticsLabel('Name: A → Z, tap to switch direction'),
        findsOneWidget,
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(byIconButton('Reverse order'));
      await h.settle(tester);
      await _openDialog(tester, 'Name');
      expect(
        find.bySemanticsLabel('Name: Z → A, tap to switch direction'),
        findsOneWidget,
      );
      expect(byIconButton('Switch direction: A → Z'), findsOneWidget);
      handle.dispose();
      await unmountApp(tester);
    });
  });

  group('page goes away while the box is open', () {
    testWidgets('the page closes it from dispose', (tester) async {
      final (container, key) = await pumpHost(tester, guarded: true);
      key.currentState!.hide();
      await tester.pumpAndSettle();
      expect(find.text('gone'), findsOneWidget);
      expect(find.text('Sort by'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(
        container.read(libraryListViewsProvider).of(BrowseList.songs).sort,
        SortOrder.by(SortCriterion.title),
      );
    });

    testWidgets('a box left open still writes through the container', (
      tester,
    ) async {
      final (container, key) = await pumpHost(tester, guarded: false);
      key.currentState!.hide();
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsOneWidget);
      await tester.tap(byIconButton('Add Year'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        container.read(libraryListViewsProvider).of(BrowseList.songs).sort,
        SortOrder([
          const SortSpec(SortCriterion.title),
          const SortSpec(SortCriterion.year, descending: true),
        ]),
      );
      expect(byIconButton('Remove Year'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('the guard closes the exact route', () {
    // The host page stays as `gone`: its own route is never the one removed.
    Future<void> expectHostKept(WidgetTester tester) async {
      expect(find.text('gone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    testWidgets('dropdown open when the page goes away', (tester) async {
      final (_, key) = await pumpHost(tester, guarded: true, dropdown: true);
      key.currentState!.hide();
      await tester.pumpAndSettle();
      expect(find.text('Advanced…'), findsNothing);
      await expectHostKept(tester);
    });

    testWidgets('dialog open when the page goes away', (tester) async {
      final (_, key) = await pumpHost(tester, guarded: true);
      key.currentState!.hide();
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing);
      await expectHostKept(tester);
    });

    testWidgets('the user closed it already: nothing more to do', (
      tester,
    ) async {
      final (_, key) = await pumpHost(tester, guarded: true);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      key.currentState!.hide();
      await tester.pumpAndSettle();
      await expectHostKept(tester);
    });

    testWidgets('closing twice is a no-op', (tester) async {
      final guard = ListSortGuard();
      final (_, key) = await pumpHost(tester, guarded: true, guard: guard);
      key.currentState!.hide();
      guard.close();
      await tester.pumpAndSettle();
      guard.close();
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing);
      await expectHostKept(tester);
    });

    testWidgets('a guard that tracked nothing does nothing', (tester) async {
      ListSortGuard().close();
      await tester.pumpAndSettle();
    });
  });

  group('one source for chosen and options', () {
    final l10n = AppLocalizationsEn();
    for (final list in BrowseList.values) {
      test('${list.name}: every chosen criterion is offered', () {
        final offered = criteriaOf(list);
        final orders = [
          defaultSortOf(list),
          // Every offered criterion, in menu order.
          SortOrder([for (final c in offered) SortSpec(c)]),
          // A stored order that names criteria the list does not offer.
          SortOrder([
            for (final c in SortCriterion.values.reversed) SortSpec(c),
          ]),
        ];
        for (final order in orders) {
          final model = sortDialogModel(l10n, list, order);
          final options = model.options.map((o) => o.value).toList();
          expect(options, offered);
          expect(model.chosen, isNotEmpty);
          expect(
            model.chosen.every((e) => options.contains(e.value)),
            isTrue,
            reason: '$order on ${list.name}',
          );
          // The rows drawn are all the entries: drag indices match the order.
          expect(
            model.chosen.map((e) => e.value),
            normalizedSortOf(list, order).specs.map((s) => s.criterion),
          );
        }
      });
    }
  });

  group('labels', () {
    final l10n = AppLocalizationsEn();
    test('chip text counts the extra criteria', () {
      expect(
        sortOrderLabel(l10n, SortOrder.by(SortCriterion.artist)),
        'Artist',
      );
      expect(
        sortOrderLabel(
          l10n,
          SortOrder([
            const SortSpec(SortCriterion.artist),
            const SortSpec(SortCriterion.year),
            const SortSpec(SortCriterion.title),
          ]),
        ),
        'Artist +2',
      );
    });
  });
}

/// A stand-in page: a button that opens the box like a list page does.
class _Page extends StatefulWidget {
  const _Page({required this.guarded, this.guard});

  final bool guarded;
  final ListSortGuard? guard;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  late final ListSortGuard _guard = widget.guard ?? ListSortGuard();
  final GlobalKey _anchor = GlobalKey();

  @override
  void dispose() {
    if (widget.guarded) _guard.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void open({required bool dropdown}) {
      final container = ProviderScope.containerOf(context);
      Future<void> write(SortOrder sort) => container
          .read(libraryListViewsProvider.notifier)
          .setSort(BrowseList.songs, sort);
      SortOrder read() =>
          container.read(libraryListViewsProvider).of(BrowseList.songs).sort;
      Future<void> reset() => write(defaultSortOf(BrowseList.songs));
      final guard = widget.guarded ? _guard : null;
      if (dropdown) {
        openListSort(
          context,
          list: BrowseList.songs,
          anchor: _anchor,
          guard: guard,
          read: read,
          write: write,
          reset: reset,
        );
      } else {
        openAdvancedSort(
          context,
          list: BrowseList.songs,
          guard: guard,
          read: read,
          write: write,
          reset: reset,
        );
      }
    }

    return Row(
      children: [
        TextButton(
          onPressed: () => open(dropdown: false),
          child: const Text('open'),
        ),
        TextButton(
          key: _anchor,
          onPressed: () => open(dropdown: true),
          child: const Text('sort'),
        ),
      ],
    );
  }
}

class _Toggle extends StatefulWidget {
  const _Toggle({super.key, required this.child});

  final Widget child;

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _shown = true;

  void hide() => setState(() => _shown = false);

  @override
  Widget build(BuildContext context) =>
      _shown ? widget.child : const Text('gone');
}
