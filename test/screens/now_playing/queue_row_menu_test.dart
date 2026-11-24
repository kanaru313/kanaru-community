import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/state/queue_row_infos.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_host.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/ui_host.dart';
import '../../support/icon_button_finders.dart';
import 'support/song_menu_pump.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/library/albums/:id',
    builder: (context, state) => const Scaffold(body: Text('album page')),
  ),
  GoRoute(
    path: '/library/artists/:id',
    builder: (context, state) => const Scaffold(body: Text('artist page')),
  ),
];

const _playThis = 'Play this track';

/// A panel on [host] with track T1 tagged (album, one artist).
Future<UiHost> _pump(
  WidgetTester tester, {
  QueueHost host = QueueHost.panel,
  bool inLibrary = true,
  Size? size,
}) async {
  final h = await pumpWithPlayer(
    tester,
    QueuePanel(host: host),
    play: false,
    routes: _routes,
    overrides: [
      extensionRegistryProvider.overrideWithValue(ExtensionRegistry()),
      // No row ever gets its info: the song is "not in the library".
      if (!inLibrary)
        queueRowInfoLoaderProvider.overrideWithValue((_) async => []),
    ],
    size:
        size ??
        (host == QueueHost.panel
            ? const Size(900, 1800)
            : const Size(400, 1800)),
  );
  await h.run(tester, () async {
    await h.h.db.customStatement(
      "UPDATE tracks SET album = 'Alb', artist = 'Art One', "
      "album_title_key = 'alb', album_artist_key = 'art one' "
      "WHERE title = 'T1'",
    );
    final id = h.h.tracks[1].value;
    await h.h.db.customStatement(
      'INSERT INTO track_artists (track_id, artist_key, artist_name, '
      "position) VALUES ($id, 'art one', 'Art One', 0)",
    );
    await h.h.play();
  });
  await h.letStreamsArrive(tester);
  return h;
}

/// Right-clicks the row titled [title] and waits for the menu.
Future<void> _openMenu(WidgetTester tester, String title) async {
  await tester.tap(
    find.text(title).first,
    buttons: kSecondaryButton,
    kind: PointerDeviceKind.mouse,
  );
  await menuLoads(tester, until: find.text(_playThis));
}

Finder _more(int row) => find.descendant(
  of: find.byType(QueueRow).at(row),
  matching: find.byIcon(KIcons.moreVert),
);

double _y(WidgetTester tester, String label) =>
    tester.getTopLeft(find.text(label)).dy;

String _location(UiHost host) =>
    host.router!.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('right click opens the song menu: groups in order, no footer, '
      'no Now Playing rows', (tester) async {
    await _pump(tester);
    await _openMenu(tester, 'T1');
    final ys = [
      for (final l in [
        _playThis,
        'Play next',
        'Go to album',
        'Go to artist',
        'Lyrics source',
        'Add to playlist…',
        'Add to favorites',
        'Select',
        'Remove from queue',
        'Advanced',
      ])
        _y(tester, l),
    ];
    expect(ys, [...ys]..sort());
    // First group = [Play this, Play next] alone, above Go to.
    expect(_y(tester, 'Play next'), lessThan(_y(tester, 'Go to album')));
    expect(find.text('Sleep timer'), findsNothing);
    expect(find.text('Translate lyrics…'), findsNothing);
    expect(find.text('Visual effects'), findsNothing);
    // The queue already holds the song: no footer.
    expect(find.text('Add to queue'), findsNothing);
    expect(find.text('Play next'), findsOneWidget);
    // The header is the song's; Remove is the danger row with its key hint.
    expect(find.text('Art One · Alb'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Remove from queue is the error-coloured row', (tester) async {
    await _pump(tester);
    await _openMenu(tester, 'T1');
    final scheme = Theme.of(tester.element(find.text(_playThis))).colorScheme;
    final icon = tester.widget<Icon>(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('Remove from queue'),
              matching: find.byType(Row),
            ),
            matching: find.byType(Icon),
          )
          .first,
    );
    expect(icon.color, scheme.error);
  });

  testWidgets('no key hint on the mobile sheet', (tester) async {
    await _pump(tester, host: QueueHost.sheet);
    await tester.tap(_more(1));
    await menuLoads(tester, until: find.text(_playThis));
    expect(find.text('Remove from queue'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('Play this track plays that entry', (tester) async {
    final host = await _pump(tester);
    final target = host.h.c.queueState.items[2].entryId;
    await _openMenu(tester, 'T2');
    await host.tap(tester, find.text(_playThis));
    expect(host.h.c.queueState.currentItem!.entryId, target);
  });

  testWidgets('Play next queues a copy right after the current entry', (
    tester,
  ) async {
    final host = await _pump(tester);
    final ids = [for (final i in host.h.c.queueState.items) i.entryId];
    await _openMenu(tester, 'T4');
    await host.tap(tester, find.text('Play next'));
    final q = host.h.c.queueState;
    expect(q.length, 7);
    expect(q.items[q.current! + 1].trackId, host.h.tracks[4]);
    expect(q.items[q.current! + 1].entryId, isNot(ids[4]));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Playing next'), findsOneWidget);
  });

  testWidgets('Select toggles the queue selection and flips its label', (
    tester,
  ) async {
    final host = await _pump(tester);
    final id = host.h.tracks[3];
    await _openMenu(tester, 'T3');
    expect(find.text('Deselect'), findsNothing);
    await host.tap(tester, find.text('Select'));
    expect(host.container.read(isSelectedProvider(id)), isTrue);
    await _openMenu(tester, 'T3');
    expect(find.text('Select'), findsNothing);
    await host.tap(tester, find.text('Deselect'));
    expect(host.container.read(isSelectedProvider(id)), isFalse);
  });

  testWidgets('Remove takes the entry out with an Undo toast', (tester) async {
    final host = await _pump(tester);
    await _openMenu(tester, 'T3');
    await host.tap(tester, find.text('Remove from queue'));
    expect(host.h.c.queueState.length, 5);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Removed “T3”'), findsOneWidget);
  });

  for (final label in [_playThis, 'Select', 'Remove from queue']) {
    testWidgets(
      'an entry that left the queue raises the stale notice ($label)',
      (tester) async {
        final host = await _pump(tester);
        final gone = host.h.c.queueState.items[2].entryId;
        await _openMenu(tester, 'T2');
        await host.run(tester, () async => host.h.c.remove({gone}));
        final before = host.h.c.queueState.length;
        final current = host.h.c.queueState.currentItem!.entryId;
        await host.tap(tester, find.text(label));
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.text('That track is no longer in the queue'),
          findsOneWidget,
        );
        expect(host.h.c.queueState.length, before);
        expect(host.h.c.queueState.currentItem!.entryId, current);
        expect(
          host.container.read(isSelectedProvider(host.h.tracks[2])),
          isFalse,
        );
      },
    );
  }

  testWidgets('a song that is not in the library shows the toast, no menu', (
    tester,
  ) async {
    await _pump(tester, inLibrary: false);
    await tester.tap(
      find.byType(QueueRow).at(1),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('This is no longer in your library.'), findsOneWidget);
    expect(find.text(_playThis), findsNothing);
  });

  testWidgets('Go to album opens the album location', (tester) async {
    final host = await _pump(tester);
    await _openMenu(tester, 'T1');
    await host.tap(tester, find.text('Go to album'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await host.letStreamsArrive(tester);
    expect(_location(host), LibraryLocations.album(AlbumKey('art one', 'alb')));
    expect(find.text('album page'), findsOneWidget);
  });

  testWidgets(
    '› opens Song info over the menu; Back returns to the same menu',
    (tester) async {
      await _pump(tester, host: QueueHost.sheet);
      await tester.tap(_more(1));
      await menuLoads(tester, until: find.text(_playThis));
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('T1'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(KOverlayPageScope), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(KOverlayPageScope),
          matching: byIconButton('Back'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(KOverlayPageScope), findsNothing);
      expect(find.text(_playThis), findsOneWidget);
      expect(find.text('Remove from queue'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    },
  );

  for (final (name, host, size) in [
    ('mobile', QueueHost.sheet, const Size(400, 800)),
    ('desktop', QueueHost.panel, const Size(1280, 800)),
  ]) {
    testWidgets('$name 800 high: scrolls to Remove from queue and taps it', (
      tester,
    ) async {
      final h = await _pump(tester, host: host, size: size);
      await _openMenu(tester, 'T3');
      // The menu is taller than the view: scroll its own scrollable.
      final remove = find.text('Remove from queue', skipOffstage: false);
      expect(tester.getRect(remove).bottom, greaterThan(800));
      await tester.ensureVisible(remove);
      await tester.pump();
      await h.tap(tester, find.text('Remove from queue'));
      expect(h.h.c.queueState.length, 5);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('⋮ on the mobile sheet opens the same menu', (tester) async {
    await _pump(tester, host: QueueHost.sheet);
    await tester.tap(_more(1));
    await menuLoads(tester, until: find.text(_playThis));
    expect(find.text(_playThis), findsOneWidget);
    expect(find.text('Go to artist'), findsOneWidget);
    expect(find.text('Add to queue'), findsNothing);
    expect(find.byType(PopupMenuItem<void>), findsNothing);
  });

  testWidgets('the Menu key on a focused row opens the menu', (tester) async {
    await _pump(tester);
    Focus.of(tester.element(_more(1))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await menuLoads(tester, until: find.text(_playThis));
    expect(find.text(_playThis), findsOneWidget);
    expect(find.byType(PopupMenuItem<void>), findsNothing);
  });

  testWidgets('a pointer press on ⋮ opens the menu', (tester) async {
    await _pump(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(QueueRow).at(1),
        matching: byIconButton('More'),
      ),
    );
    await menuLoads(tester, until: find.text(_playThis));
    expect(find.text(_playThis), findsOneWidget);
  });

  testWidgets('the Delete key on a row still removes it directly', (
    tester,
  ) async {
    final host = await _pump(tester);
    Focus.of(tester.element(_more(1))).requestFocus();
    await tester.pump();
    await host.run(
      tester,
      () => tester.sendKeyEvent(LogicalKeyboardKey.delete),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(host.h.c.queueState.length, 5);
    expect(find.text(_playThis), findsNothing);
  });
}
