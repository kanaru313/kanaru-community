import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_host.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_panel.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/ui_host.dart';

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

/// A panel on [host] with track T1 tagged (album, one or two artists).
Future<UiHost> _pump(
  WidgetTester tester, {
  QueueHost host = QueueHost.panel,
  List<String> artists = const ['Art One'],
}) async {
  final h = await pumpWithPlayer(
    tester,
    QueuePanel(host: host),
    play: false,
    routes: _routes,
    size: host == QueueHost.panel ? const Size(900, 800) : const Size(400, 800),
  );
  await h.run(tester, () async {
    await h.h.db.customStatement(
      "UPDATE tracks SET album = 'Alb', artist = '${artists.first}', "
      "album_title_key = 'alb', album_artist_key = 'art one' "
      "WHERE title = 'T1'",
    );
    final id = h.h.tracks[1].value;
    for (var i = 0; i < artists.length; i++) {
      await h.h.db.customStatement(
        'INSERT INTO track_artists (track_id, artist_key, artist_name, '
        "position) VALUES ($id, '${artists[i].toLowerCase()}', "
        "'${artists[i]}', $i)",
      );
    }
    await h.h.play();
  });
  await h.letStreamsArrive(tester);
  return h;
}

Future<void> _openMenu(WidgetTester tester, String title) async {
  await tester.tap(
    find.text(title),
    buttons: kSecondaryButton,
    kind: PointerDeviceKind.mouse,
  );
  // The route's animation starts on the second frame.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

String _location(UiHost host) =>
    host.router!.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('right click opens the menu with every entry', (tester) async {
    await _pump(tester);
    await _openMenu(tester, 'T1');
    for (final label in [
      'Play this track',
      'Play next',
      'Go to album',
      'Go to artist',
      'Ask AI',
      'Remove from queue',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // Not built yet: marked, and Remove carries its key hint.
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    final ai = tester.widget<PopupMenuItem<void>>(
      find.ancestor(
        of: find.text('Ask AI'),
        matching: find.byType(PopupMenuItem<void>),
      ),
    );
    expect(ai.enabled, isFalse);
  });

  testWidgets('Play this track plays that entry', (tester) async {
    final host = await _pump(tester);
    final target = host.h.c.queueState.items[2].entryId;
    await _openMenu(tester, 'T2');
    await host.tap(tester, find.text('Play this track'));
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
    // The original T4 entry is still there; the copy is a new entry.
    expect(q.indexOfEntry(ids[4]), greaterThan(0));
    expect(q.items[q.current! + 1].trackId, host.h.tracks[4]);
    expect(q.items[q.current! + 1].entryId, isNot(ids[4]));
  });

  testWidgets('Remove takes the entry out with an Undo toast', (tester) async {
    final host = await _pump(tester);
    await _openMenu(tester, 'T3');
    await host.tap(tester, find.text('Remove from queue'));
    expect(host.h.c.queueState.length, 5);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Removed “T3”'), findsOneWidget);
  });

  testWidgets('an entry that left the queue raises the stale notice', (
    tester,
  ) async {
    final host = await _pump(tester);
    final gone = host.h.c.queueState.items[2].entryId;
    await _openMenu(tester, 'T2');
    await host.run(tester, () async => host.h.c.remove({gone}));
    await host.tap(tester, find.text('Play this track'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('That track is no longer in the queue'), findsOneWidget);
    expect(host.h.c.queueState.length, 5);
  });

  testWidgets('Go to album opens the album location', (tester) async {
    final host = await _pump(tester);
    await _openMenu(tester, 'T1');
    await host.tap(tester, find.text('Go to album'));
    await tester.pump();
    expect(_location(host), LibraryLocations.album(AlbumKey('art one', 'alb')));
    expect(find.text('album page'), findsOneWidget);
  });

  testWidgets('Go to artist opens the artist location', (tester) async {
    final host = await _pump(tester);
    await _openMenu(tester, 'T1');
    await host.tap(tester, find.text('Go to artist'));
    await tester.pump();
    expect(
      _location(host),
      LibraryLocations.artist(ArtistKey(groupKey('Art One'))),
    );
  });

  testWidgets('several artists ask which one first', (tester) async {
    final host = await _pump(tester, artists: ['Art One', 'Art Two']);
    await _openMenu(tester, 'T1');
    await host.tap(tester, find.text('Go to artist'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose an artist'), findsOneWidget);
    expect(find.text('Art Two'), findsOneWidget);
    await tester.tap(find.text('Art Two'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The menu action started in the real zone: let it resume.
    await host.letStreamsArrive(tester);
    expect(
      _location(host),
      LibraryLocations.artist(ArtistKey(groupKey('Art Two'))),
    );
  });

  testWidgets('a track without an album has Go to album dimmed', (
    tester,
  ) async {
    await _pump(tester);
    await _openMenu(tester, 'T2');
    final item = tester.widget<PopupMenuItem<void>>(
      find.ancestor(
        of: find.text('Go to album'),
        matching: find.byType(PopupMenuItem<void>),
      ),
    );
    expect(item.enabled, isFalse);
    // The item exists: it is not "coming soon", only unavailable here.
    expect(
      find.descendant(
        of: find.byWidget(item),
        matching: find.text('Coming soon'),
      ),
      findsNothing,
    );
  });

  testWidgets('on the mobile sheet a long press opens the menu as a sheet', (
    tester,
  ) async {
    await _pump(tester, host: QueueHost.sheet);
    await tester.longPress(find.text('T1'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Play this track'), findsOneWidget);
    expect(find.text('Go to artist'), findsOneWidget);
    expect(find.byType(PopupMenuItem<void>), findsNothing);
  });

  for (final host in QueueHost.values) {
    testWidgets('Enter on ⋮ focuses the first row (${host.name})', (
      tester,
    ) async {
      await _pump(tester, host: host);
      final more = find.descendant(
        of: find.byType(QueueRow).at(1),
        matching: find.byIcon(KIcons.moreVert),
      );
      Focus.of(tester.element(more)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      expect(FocusManager.instance.primaryFocus, isNot(isA<FocusScopeNode>()));
      final focused = FocusManager.instance.primaryFocus!.context!;
      var onFirstRow = false;
      tester.element(find.text('Play this track')).visitAncestorElements((e) {
        if (identical(e, focused)) onFirstRow = true;
        return !onFirstRow;
      });
      expect(onFirstRow, isTrue);
    });
  }

  testWidgets('the Menu key on a focused row opens the menu on its first row', (
    tester,
  ) async {
    await _pump(tester);
    final more = find.descendant(
      of: find.byType(QueueRow).at(1),
      matching: find.byIcon(KIcons.moreVert),
    );
    Focus.of(tester.element(more)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Play this track'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, isNot(isA<FocusScopeNode>()));
  });

  testWidgets('a pointer press on ⋮ leaves focus off the menu rows', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(QueueRow).at(1),
        matching: find.byTooltip('More'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Only the menu route's own scope has focus: no row shows a ring.
    expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
  });
}
