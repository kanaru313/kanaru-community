import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/ui/selection/selection_panel.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/ui/queue/queue_actions.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_host.dart';
import 'package:kanaru/src/screens/now_playing/ui/queue_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/controller_harness.dart' show ctx;
import '../../playback/support/ui_host.dart';

/// A router, which the selection panel's Back handling needs.
final _routes = <RouteBase>[];

UiHost? _live;

Future<UiHost> _pump(
  WidgetTester tester, {
  QueueHost host = QueueHost.sheet,
  bool play = true,
  Size size = const Size(400, 800),
}) async => _live = await pumpWithPlayer(
  tester,
  QueuePanel(host: host),
  play: play,
  size: size,
  routes: _routes,
);

/// A widget test that ends with an empty selection and lets the panel's
/// throttled duration read run out, so no timer outlives the tree.
void _test(String name, Future<void> Function(WidgetTester tester) body) =>
    testWidgets(name, (tester) async {
      _live = null;
      await body(tester);
      final host = _live;
      if (host == null) return;
      host.container.read(librarySelectionProvider.notifier).clear();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
    });

List<TrackId> _selected(UiHost host) =>
    host.container.read(librarySelectionProvider).ids;

/// The tracks picked, as harness indexes.
List<int> _picked(UiHost host) => [
  for (final id in _selected(host)) id.value - host.h.tracks.first.value,
];

void _pick(UiHost host, int track) => host.container
    .read(librarySelectionProvider.notifier)
    .toggle(host.h.tracks[track]);

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(QueueRow));

Finder _check(Finder row) =>
    find.descendant(of: row, matching: find.byIcon(KIcons.check));

Future<void> _openRowMenu(WidgetTester tester, String title) async {
  await tester.tap(
    find.descendant(of: _row(title), matching: find.byIcon(KIcons.moreVert)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tapWith(
  WidgetTester tester,
  UiHost host,
  LogicalKeyboardKey key,
  String title,
) async {
  await tester.sendKeyDownEvent(key);
  await host.tap(tester, find.text(title));
  await tester.sendKeyUpEvent(key);
}

Future<void> _swipe(WidgetTester tester, UiHost host, String title) async {
  await tester.runAsync(() async {
    final width = tester.getSize(find.byType(KSwipeActions).first).width;
    final g = await tester.startGesture(
      tester.getCenter(find.text(title)),
      kind: PointerDeviceKind.touch,
    );
    await g.moveBy(Offset(width * 0.4, 0));
    await g.moveBy(Offset(width * 0.4, 0));
    await tester.pump();
    await g.up();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await host.h.settle();
  });
  await tester.pump();
  await host.letStreamsArrive(tester);
}

void main() {
  group('entering', () {
    _test('the head menu selects the current song', (tester) async {
      final host = await _pump(tester);
      await tester.tap(find.byIcon(KIcons.moreVert).first);
      await tester.pump();
      await tester.tap(find.text('Select several'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_picked(host), [0]);
      expect(find.byType(SelectionPanel), findsOneWidget);
      expect(_check(_row('T0')), findsOneWidget);
    });

    _test('the head menu item is dimmed with no current song', (tester) async {
      final host = await _pump(tester, play: false);
      await tester.tap(find.byIcon(KIcons.moreVert).first);
      await tester.pump();
      final item = tester.widget<MenuItemButton>(
        find.ancestor(
          of: find.text('Select several'),
          matching: find.byType(MenuItemButton),
        ),
      );
      expect(item.onPressed, isNull);
      expect(_selected(host), isEmpty);
    });

    _test('the row menu selects and deselects', (tester) async {
      final host = await _pump(tester);
      await _openRowMenu(tester, 'T2');
      expect(find.text('Deselect'), findsNothing);
      await tester.tap(find.text('Select'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_picked(host), [2]);
      expect(_check(_row('T2')), findsOneWidget);

      await _openRowMenu(tester, 'T2');
      expect(find.text('Select'), findsNothing);
      await tester.tap(find.text('Deselect'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_selected(host), isEmpty);
      expect(_check(_row('T2')), findsNothing);
    });

    _test('a long press selects the row, the menu stays on ⋮', (tester) async {
      final host = await _pump(tester);
      await tester.longPress(find.text('T3'));
      expect(_picked(host), [3]);
      expect(find.text('Play this track'), findsNothing);
    });
  });

  group('while selecting', () {
    _test('a tap toggles the row and does not play it', (tester) async {
      final host = await _pump(tester);
      _pick(host, 1);
      await tester.pump();
      final current = host.h.c.queueState.currentItem!.entryId;
      await host.tap(tester, find.text('T4'));
      expect(_picked(host), [1, 4]);
      expect(host.h.c.queueState.currentItem!.entryId, current);
      await host.tap(tester, find.text('T4'));
      expect(_picked(host), [1]);
    });

    _test('Ctrl+click toggles without a selection, nothing plays', (
      tester,
    ) async {
      final host = await _pump(tester);
      final current = host.h.c.queueState.currentItem!.entryId;
      await _tapWith(tester, host, LogicalKeyboardKey.controlLeft, 'T2');
      expect(_picked(host), [2]);
      expect(host.h.c.queueState.currentItem!.entryId, current);
    });

    _test('Shift+click ranges over queue positions, not track ids', (
      tester,
    ) async {
      final host = await _pump(tester);
      // T1 is queued again at the end: entries T0..T5, T1.
      await host.run(tester, () => host.h.c.enqueue([host.h.tracks[1]]));
      await host.letStreamsArrive(tester);
      final rows = find.byType(QueueRow);
      expect(rows, findsNWidgets(7));
      // Anchor: the second T1 (last row). Then Shift+click T5.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await host.tap(tester, find.text('T1').last);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _tapWith(tester, host, LogicalKeyboardKey.shiftLeft, 'T5');
      // Entries 5..6 only: T5 and T1. A range from the first T1 would also
      // have taken T2, T3 and T4.
      expect(_picked(host)..sort(), [1, 5]);
    });

    _test('Shift+click ranges both ways and grows from the last click', (
      tester,
    ) async {
      final host = await _pump(tester);
      await _tapWith(tester, host, LogicalKeyboardKey.controlLeft, 'T4');
      await _tapWith(tester, host, LogicalKeyboardKey.shiftLeft, 'T2');
      expect(_picked(host)..sort(), [2, 3, 4]);
      await _tapWith(tester, host, LogicalKeyboardKey.shiftLeft, 'T0');
      expect(_picked(host)..sort(), [0, 1, 2, 3, 4]);
    });

    _test('Shift+click without a usable anchor only selects the row', (
      tester,
    ) async {
      final host = await _pump(tester);
      await _tapWith(tester, host, LogicalKeyboardKey.shiftLeft, 'T3');
      expect(_picked(host), [3]);
      // The anchor row leaves the queue: Shift acts as a plain select.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await host.tap(tester, find.text('T2'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      final anchor = host.h.c.queueState.items[2].entryId;
      await host.run(tester, () => host.h.c.remove({anchor}));
      await host.letStreamsArrive(tester);
      await _tapWith(tester, host, LogicalKeyboardKey.shiftLeft, 'T5');
      expect(_picked(host)..sort(), [2, 3, 5]);
    });

    _test('Shift+click after the anchor track was deselected only selects', (
      tester,
    ) async {
      final host = await _pump(tester);
      await _tapWith(tester, host, LogicalKeyboardKey.controlLeft, 'T4');
      await _tapWith(tester, host, LogicalKeyboardKey.controlLeft, 'T4');
      expect(_picked(host), isEmpty);
      _pick(host, 0);
      await tester.pump();
      await _tapWith(tester, host, LogicalKeyboardKey.shiftLeft, 'T2');
      expect(_picked(host), [0, 2]);
    });

    _test('a selection ended starts the next range afresh', (tester) async {
      final host = await _pump(tester);
      await _tapWith(tester, host, LogicalKeyboardKey.controlLeft, 'T4');
      host.container.read(librarySelectionProvider.notifier).clear();
      await tester.pump();
      await _tapWith(tester, host, LogicalKeyboardKey.shiftLeft, 'T1');
      expect(_picked(host), [1]);
    });

    _test(
      'a selection made after an emptied one does not range from the old anchor',
      (tester) async {
        final host = await _pump(tester);
        await _tapWith(tester, host, LogicalKeyboardKey.controlLeft, 'T4');
        host.container.read(librarySelectionProvider.notifier).clear();
        // Nobody watches the selection now; a selection made elsewhere (the
        // library) must not range from the old queue anchor.
        _pick(host, 0);
        await tester.pump();
        await _tapWith(tester, host, LogicalKeyboardKey.shiftLeft, 'T2');
        expect(_picked(host), [0, 2]);
      },
    );

    _test('swiping a row out still removes it', (tester) async {
      final host = await _pump(tester);
      _pick(host, 1);
      await tester.pump();
      await _swipe(tester, host, 'T3');
      expect(host.h.c.queueState.length, 5);
      expect(_picked(host), [1]);
    });

    _test('a replaced queue keeps the selection, new rows follow it', (
      tester,
    ) async {
      final host = await _pump(tester);
      _pick(host, 2);
      await tester.pump();
      await host.run(
        tester,
        () => host.h.c.playTracks([
          host.h.tracks[4],
          host.h.tracks[2],
          host.h.tracks[5],
        ], context: ctx),
      );
      await host.letStreamsArrive(tester);
      expect(_picked(host), [2]);
      expect(find.byType(QueueRow), findsNWidgets(3));
      expect(_check(_row('T2')), findsOneWidget);
      expect(_check(_row('T4')), findsNothing);
      expect(_check(_row('T5')), findsNothing);
    });
  });

  group('the sheet panel', () {
    _test('floats above the footer, only while something is selected', (
      tester,
    ) async {
      final host = await _pump(tester);
      expect(find.byType(SelectionPanel), findsNothing);
      _pick(host, 1);
      await tester.pump();
      expect(find.byType(SelectionPanel), findsOneWidget);
      expect(find.byType(QueueActions), findsOneWidget);
      expect(
        tester.getRect(find.byType(SelectionPanel)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(QueueActions)).top),
      );
      host.container.read(librarySelectionProvider.notifier).clear();
      await tester.pump();
      expect(find.byType(SelectionPanel), findsNothing);
    });

    _test('the desktop panel host shows none', (tester) async {
      final host = await _pump(
        tester,
        host: QueueHost.panel,
        size: const Size(900, 800),
      );
      _pick(host, 1);
      await tester.pump();
      expect(find.byType(SelectionPanel), findsNothing);
      expect(_check(_row('T1')), findsOneWidget);
    });
  });
}
