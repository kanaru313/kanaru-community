import 'package:flutter/semantics.dart'
    show CustomSemanticsAction, SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/domain/queue_state.dart';
import 'package:kanaru/src/playback/ui/queue/queue_list.dart';
import 'package:kanaru/src/playback/ui/queue/queue_locate_button.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row_hooks.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'queue_test_support.dart';

/// A stand-in for the app's selection: the tracks picked so far.
class _Picked extends Notifier<Set<TrackId>> {
  @override
  Set<TrackId> build() => {};

  void toggle(TrackId id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
}

final _picked = NotifierProvider<_Picked, Set<TrackId>>(_Picked.new);
final _isPicked = Provider.family<bool, TrackId>(
  (ref, id) => ref.watch(_picked.select((s) => s.contains(id))),
);
final _anyPicked = Provider<bool>(
  (ref) => ref.watch(_picked.select((s) => s.isNotEmpty)),
);

void main() {
  late ProviderContainer container;
  final gestures = <String>[];
  final menus = <int>[];
  final builds = <TrackId, int>{};

  setUp(() {
    gestures.clear();
    menus.clear();
    builds.clear();
  });

  QueueList list({double bottomInset = 0}) => QueueList(
    size: QueueRowSize.mobile,
    bottomInset: bottomInset,
    menu: (context, item, info, at, {viaKeyboard = false}) =>
        menus.add(item.entryId),
    selection: QueueRowSelection(
      isSelected: (id) {
        builds[id] = (builds[id] ?? 0) + 1;
        return _isPicked(id);
      },
      selecting: _anyPicked,
      onSelect: (item, {range = false}) {
        gestures.add('${range ? 'range' : 'toggle'}:${item.entryId}');
        if (!range) container.read(_picked.notifier).toggle(item.trackId);
      },
    ),
  );

  Future<void> pump(
    WidgetTester tester, {
    QueueView? view,
    double bottomInset = 0,
  }) async {
    container = await pumpFakeQueue(
      tester,
      list(bottomInset: bottomInset),
      view: view ?? fakeView(6, current: 2),
    );
  }

  void pick(WidgetTester tester, int track) {
    container.read(_picked.notifier).toggle(TrackId(track));
  }

  Finder row(int index) => find.byType(QueueRow).at(index);
  Finder checkIn(Finder r) =>
      find.descendant(of: r, matching: find.byIcon(KIcons.check));
  Finder handleOf(int index) => find.descendant(
    of: row(index),
    matching: find.byType(ReorderableDragStartListener),
  );

  double minOpacityAbove(Finder target) {
    var lowest = 1.0;
    for (final e
        in find
            .ancestor(of: target, matching: find.byType(Opacity))
            .evaluate()) {
      final value = (e.widget as Opacity).opacity;
      if (value < lowest) lowest = value;
    }
    return lowest;
  }

  group('row states', () {
    testWidgets('idle, current, selected, current + selected, played + '
        'selected', (tester) async {
      await pump(tester);
      // Nothing selected: no ✓, the current row has its equalizer.
      expect(find.byIcon(KIcons.check), findsNothing);
      expect(find.byType(KEqualizerIcon), findsOneWidget);

      pick(tester, 4); // upcoming
      await tester.pump();
      expect(checkIn(row(4)), findsOneWidget);
      expect(checkIn(row(3)), findsNothing);

      pick(tester, 2); // current: the ✓ replaces the equalizer
      await tester.pump();
      expect(checkIn(row(2)), findsOneWidget);
      expect(find.byType(KEqualizerIcon), findsNothing);

      pick(tester, 0); // played: dimmed, ✓ still clear
      await tester.pump();
      expect(checkIn(row(0)), findsOneWidget);
      expect(minOpacityAbove(checkIn(row(0))), 1);
      expect(minOpacityAbove(find.text('Song 0')), lessThan(1));

      pick(tester, 2); // deselected: the equalizer is back
      await tester.pump();
      expect(checkIn(row(2)), findsNothing);
      expect(find.byType(KEqualizerIcon), findsOneWidget);
    });

    testWidgets('every occurrence of a selected track shows selected', (
      tester,
    ) async {
      await pump(
        tester,
        view: QueueView(
          items: [
            for (final (i, t) in [0, 1, 0, 2].indexed)
              QueueItem(entryId: i + 1, trackId: TrackId(t), sortKey: 'k$i'),
          ],
          current: 1,
        ),
      );
      pick(tester, 0);
      await tester.pump();
      expect(checkIn(row(0)), findsOneWidget);
      expect(checkIn(row(2)), findsOneWidget);
      expect(checkIn(row(1)), findsNothing);
      expect(checkIn(row(3)), findsNothing);
    });

    testWidgets('a selection change rebuilds only the rows of that track', (
      tester,
    ) async {
      await pump(tester, view: fakeView(8, current: 0));
      final before = {...builds};
      expect(before.keys.length, 8);
      pick(tester, 3);
      await tester.pump();
      for (final id in before.keys) {
        expect(
          builds[id]! - before[id]!,
          id == TrackId(3) ? greaterThan(0) : 0,
          reason: 'track ${id.value}',
        );
      }
    });
  });

  group('gestures', () {
    testWidgets('while selecting a tap toggles, on the current row too', (
      tester,
    ) async {
      await pump(tester);
      pick(tester, 5);
      await tester.pump();
      // No player is wired: a tap that played would throw.
      await tester.tap(find.text('Song 3'));
      await tester.tap(find.text('Song 2')); // the current row
      expect(gestures, ['toggle:4', 'toggle:3']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ctrl+click toggles and Shift+click asks for a range', (
      tester,
    ) async {
      await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('Song 2')); // current row, not selecting
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(find.text('Song 4'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(gestures, ['toggle:3', 'range:5']);
    });

    testWidgets('a long press selects, again deselects, and opens no menu', (
      tester,
    ) async {
      await pump(tester);
      await tester.longPress(find.text('Song 3'));
      expect(container.read(_picked), {TrackId(3)});
      expect(checkIn(row(3)), findsOneWidget);
      await tester.longPress(find.text('Song 3'));
      expect(container.read(_picked), isEmpty);
      // Selecting: a long press on another row adds it.
      pick(tester, 0);
      await tester.longPress(find.text('Song 4'));
      expect(container.read(_picked), {TrackId(0), TrackId(4)});
      expect(menus, isEmpty);
    });

    testWidgets('a long press on the handle neither selects nor opens', (
      tester,
    ) async {
      await pump(tester);
      await tester.longPress(handleOf(3));
      expect(gestures, isEmpty);
      expect(menus, isEmpty);
    });

    testWidgets('the screen-reader long press selects, labelled Select', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      final node = tester.getSemantics(find.text('Song 3'));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.longPress),
        isTrue,
      );
      final hints = [
        for (final id in node.getSemanticsData().customSemanticsActionIds ?? [])
          CustomSemanticsAction.getAction(id)!.hint,
      ];
      expect(hints, contains('Select'));
      tester.semantics.performAction(
        find.semantics.byPredicate((n) => n.id == node.id),
        SemanticsAction.longPress,
      );
      await tester.pump();
      expect(gestures, ['toggle:4']);
      expect(menus, isEmpty);
      semantics.dispose();
    });
  });

  group('room for a floating panel', () {
    testWidgets('the last row and the locate button stay above it', (
      tester,
    ) async {
      await pump(tester, view: fakeView(30, current: 0), bottomInset: 80);
      final area = tester.getRect(find.byType(QueueList));
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      await tester.pump();
      expect(find.byType(QueueLocateButton), findsOneWidget);
      expect(
        tester.getRect(find.byType(QueueLocateButton)).bottom,
        lessThanOrEqualTo(area.bottom - 80),
      );
      expect(
        tester.getRect(find.byType(QueueRow).last).bottom,
        lessThanOrEqualTo(area.bottom - 80),
      );
    });
  });
}
