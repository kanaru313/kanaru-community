import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/ui/queue/queue_actions.dart';
import 'package:kanaru/src/playback/ui/queue/queue_header.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/controller_harness.dart' show ctx;
import '../../support/ui_host.dart';

Widget _actions({bool up = false}) => Align(
  alignment: up ? Alignment.bottomCenter : Alignment.topCenter,
  child: QueueActions(menuUp: up),
);

MenuItemButton _item(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(MenuItemButton)),
);

Future<void> _openCleanup(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Clean up'));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Queues [indexes] of the harness tracks (a track may repeat) and starts at
/// [start].
Future<void> _queue(
  WidgetTester tester,
  UiHost host,
  List<int> indexes, {
  int start = 0,
}) async {
  await host.run(
    tester,
    () => host.h.c.playTracks(
      [for (final i in indexes) host.h.tracks[i]],
      startIndex: start,
      context: ctx,
    ),
  );
  await host.letStreamsArrive(tester);
}

void main() {
  testWidgets('cleanup lists four choices with the number each removes', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _actions(), play: false);
    // Track 0 is queued twice and is the current one.
    await _queue(tester, host, [0, 1, 0, 2, 1], start: 0);
    await _openCleanup(tester);
    expect(find.text('Remove from queue'), findsOneWidget);
    for (final (label, n) in [
      ('Duplicate tracks', '2'),
      ('Earlier tracks', '0'),
      ('Later tracks', '4'),
      ('All except the current track', '4'),
    ]) {
      final row = find.ancestor(
        of: find.text(label),
        matching: find.byType(MenuItemButton),
      );
      expect(
        find.descendant(of: row, matching: find.text(n)),
        findsOneWidget,
        reason: label,
      );
    }
    expect(_item(tester, 'Earlier tracks').onPressed, isNull);
    expect(_item(tester, 'Later tracks').onPressed, isNotNull);
  });

  testWidgets('at the last entry "later tracks" is dimmed', (tester) async {
    final host = await pumpWithPlayer(tester, _actions(), play: false);
    await _queue(tester, host, [0, 1, 2], start: 2);
    await _openCleanup(tester);
    expect(_item(tester, 'Later tracks').onPressed, isNull);
    expect(_item(tester, 'Earlier tracks').onPressed, isNotNull);
  });

  testWidgets('a choice removes entries and offers Undo; current stays', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _actions(), play: false);
    await _queue(tester, host, [0, 1, 0, 2], start: 0);
    final current = host.h.c.queueState.currentItem!.entryId;
    await _openCleanup(tester);
    await host.tap(tester, find.text('Duplicate tracks'));
    expect(host.h.c.queueState.length, 3);
    expect(host.h.c.queueState.currentItem!.entryId, current);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Removed 1 track'), findsOneWidget);
    // Pressed in the real zone: the undo is a controller command.
    await host.run(
      tester,
      () async => tester
          .widget<SnackBarAction>(find.byType(SnackBarAction))
          .onPressed(),
    );
    expect(host.h.c.queueState.length, 4);
  });

  testWidgets('the toast counts what was removed when the choice ran', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _actions(), play: false);
    await _queue(tester, host, [0, 1, 0, 2], start: 0);
    // Opened at entry 0: "later tracks" would remove 3.
    await _openCleanup(tester);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Later tracks'),
          matching: find.byType(MenuItemButton),
        ),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    // The player moves on while the menu is open: now it removes 2.
    await host.run(tester, host.h.c.next);
    await host.tap(tester, find.text('Later tracks'));

    expect(host.h.c.queueState.length, 2);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Removed 2 tracks'), findsOneWidget);
    await host.run(
      tester,
      () async => tester
          .widget<SnackBarAction>(find.byType(SnackBarAction))
          .onPressed(),
    );
    expect(host.h.c.queueState.length, 4);
  });

  testWidgets('the dropdown opens upward on mobile, downward on desktop', (
    tester,
  ) async {
    await pumpWithPlayer(tester, _actions(up: true));
    final button = tester.getRect(find.byTooltip('Clean up'));
    await _openCleanup(tester);
    final menu = tester.getRect(find.text('Remove from queue'));
    expect(menu.bottom, lessThanOrEqualTo(button.top + 1));
  });

  testWidgets('desktop dropdown opens downward', (tester) async {
    await pumpWithPlayer(tester, _actions());
    final button = tester.getRect(find.byTooltip('Clean up'));
    await _openCleanup(tester);
    final menu = tester.getRect(find.text('Remove from queue'));
    expect(menu.top, greaterThanOrEqualTo(button.bottom - 1));
  });

  testWidgets('Add tracks and Save as playlist are dimmed with "Soon"', (
    tester,
  ) async {
    await pumpWithPlayer(tester, _actions());
    for (final tip in [
      'Add tracks · Coming soon',
      'Save as playlist · Coming soon',
    ]) {
      final button = tester.widget<IconButton>(
        find
            .ancestor(
              of: find.byTooltip(tip),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(button.onPressed, isNull, reason: tip);
    }
  });

  testWidgets('Shuffle turns shuffle on and reshuffles the upcoming', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _actions());
    await host.tap(tester, find.byTooltip('Shuffle'));
    expect(host.h.c.queueState.shuffled, isTrue);
    expect(host.h.c.queueState.currentItem!.trackId, const TrackId(1));
  });

  testWidgets('the more menu holds only a dimmed "Select several"', (
    tester,
  ) async {
    await pumpWithPlayer(tester, const Align(child: QueueMoreMenu()));
    await tester.tap(find.byTooltip('More'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_item(tester, 'Select several').onPressed, isNull);
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
