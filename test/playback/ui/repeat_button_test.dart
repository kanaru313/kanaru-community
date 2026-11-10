import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru/src/playback/state/queue_view_provider.dart';
import 'package:kanaru/src/playback/ui/repeat_button.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../support/ui_host.dart';

const _off = 'Stop at the end';
const _one = 'Repeat this song';
const _all = 'Repeat the whole queue';
const _shuffled = 'Repeat the whole queue, reshuffled every pass';

Future<UiHost> _pump(
  WidgetTester tester, {
  Size size = const Size(1280, 700),
  bool play = true,
}) => pumpWithPlayer(
  tester,
  const Align(alignment: Alignment.bottomCenter, child: RepeatButton()),
  size: size,
  play: play,
);

Future<void> _open(UiHost host, WidgetTester tester) async {
  await host.tap(tester, find.byType(RepeatButton));
  await tester.pumpAndSettle();
}

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SelectionRow));

SelectionRow _rowWidget(WidgetTester tester, String title) =>
    tester.widget<SelectionRow>(_row(title).first);

int _times(UiHost host) =>
    host.container.read(queueViewProvider).requireValue.repeatTimes;

Finder get _counted => find.textContaining('more time');

void main() {
  testWidgets('stopped at the end: plain icon, no dot, tooltip names it', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byTooltip(_off), findsOneWidget);
    expect(find.byIcon(KIcons.repeat), findsOneWidget);
    expect(find.byKey(KToggleIconButton.dotKey), findsNothing);
  });

  testWidgets('disabled while the queue is empty', (tester) async {
    await _pump(tester, play: false);
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
  });

  for (final (name, size) in [
    ('desktop', const Size(1280, 700)),
    ('mobile', const Size(400, 800)),
  ]) {
    group(name, () {
      testWidgets('the menu lists the five choices in order', (tester) async {
        final host = await _pump(tester, size: size);
        await _open(host, tester);
        expect(find.byType(SelectionRow), findsNWidgets(5));
        final titles = [
          _off,
          _one,
          'Repeat this song 1 more time',
          _all,
          _shuffled,
        ];
        double? last;
        for (final t in titles) {
          expect(find.text(t), findsOneWidget, reason: t);
          final y = tester.getTopLeft(_row(t)).dy;
          if (last != null) expect(y, greaterThan(last), reason: t);
          last = y;
        }
        expect(find.byType(Radio), findsNothing);
        expect(find.byType(RadioListTile), findsNothing);
      });

      testWidgets('the current mode is the selected row, with a check', (
        tester,
      ) async {
        final host = await _pump(tester, size: size);
        await _open(host, tester);
        final selected = [
          for (final e in tester.widgetList<SelectionRow>(
            find.byType(SelectionRow),
          ))
            e.selected,
        ];
        expect(selected, [true, false, false, false, false]);
        final scheme = Theme.of(tester.element(find.byType(SelectionRow).first))
            .colorScheme;
        Color checkColor(String title) => tester
            .widget<Icon>(
              find.descendant(
                of: _row(title),
                matching: find.byIcon(KIcons.check),
              ),
            )
            .color!;
        expect(checkColor(_off), scheme.primary);
        expect(checkColor(_one).a, 0, reason: 'empty slot, not removed');
      });

      testWidgets('choosing a mode sets it and closes the menu', (
        tester,
      ) async {
        final host = await _pump(tester, size: size);
        for (final (title, mode) in [
          (_one, RepeatMode.one),
          (_all, RepeatMode.all),
          (_shuffled, RepeatMode.allShuffled),
          (_off, RepeatMode.off),
        ]) {
          await _open(host, tester);
          await host.tap(tester, find.text(title));
          await tester.pumpAndSettle();
          expect(
            host.container.read(repeatSettingProvider),
            mode,
            reason: title,
          );
          expect(find.byType(SelectionRow), findsNothing, reason: 'closed');
        }
      });

      testWidgets('icon and dot follow the mode', (tester) async {
        final host = await _pump(tester, size: size);
        await host.run(tester, () => host.h.c.setRepeat(RepeatMode.one));
        expect(find.byIcon(KIcons.repeatOne), findsOneWidget);
        expect(find.byKey(KToggleIconButton.dotKey), findsOneWidget);
        await host.run(tester, () => host.h.c.setRepeat(RepeatMode.all));
        expect(find.byIcon(KIcons.repeat), findsOneWidget);
        expect(find.byKey(KToggleIconButton.dotKey), findsOneWidget);
        await host.run(
          tester,
          () => host.h.c.setRepeat(RepeatMode.allShuffled),
        );
        expect(find.byIcon(KIcons.shuffle), findsOneWidget, reason: 'badge');
        expect(find.byIcon(KIcons.repeat), findsOneWidget);
        expect(find.byKey(KToggleIconButton.dotKey), findsOneWidget);
        await host.run(tester, () => host.h.c.setRepeat(RepeatMode.off));
        expect(find.byKey(KToggleIconButton.dotKey), findsNothing);
      });
    });
  }

  group('counted row', () {
    Finder minus() => find.byKey(KCountStepper.decreaseKey);
    Finder plus() => find.byKey(KCountStepper.increaseKey);
    bool enabled(WidgetTester tester, Finder f) =>
        tester.widget<IconButton>(f).onPressed != null;

    testWidgets('stepping before arming changes the draft only', (
      tester,
    ) async {
      final host = await _pump(tester);
      await _open(host, tester);
      expect(enabled(tester, minus()), isFalse, reason: 'bound 1');
      await tester.tap(plus());
      await tester.pumpAndSettle();
      await tester.tap(plus());
      await tester.pumpAndSettle();
      expect(find.text('Repeat this song 3 more times'), findsOneWidget);
      expect(host.container.read(repeatSettingProvider), RepeatMode.off);
      expect(
        _rowWidget(tester, 'Repeat this song 3 more times').selected,
        isFalse,
      );
      // Choosing the row arms the number shown.
      await host.tap(tester, find.text('Repeat this song 3 more times'));
      await tester.pumpAndSettle();
      expect(_times(host), 3);
    });

    testWidgets('while counting the stepper changes the live count and the '
        'icon shows the number', (tester) async {
      final host = await _pump(tester);
      await host.run(tester, () => host.h.c.setRepeatTimes(5));
      expect(find.text('5'), findsOneWidget, reason: 'circled count');
      expect(find.byKey(KToggleIconButton.dotKey), findsOneWidget);
      expect(find.byTooltip('Repeat this song 5 more times'), findsOneWidget);
      await _open(host, tester);
      expect(
        _rowWidget(tester, 'Repeat this song 5 more times').selected,
        isTrue,
      );
      expect(_rowWidget(tester, _off).selected, isFalse);
      await host.tap(tester, plus());
      expect(_times(host), 6);
      await host.tap(tester, minus());
      await host.tap(tester, minus());
      expect(_times(host), 4);
    });

    testWidgets('the bounds are 1 and 99', (tester) async {
      final host = await _pump(tester);
      await host.run(tester, () => host.h.c.setRepeatTimes(99));
      await _open(host, tester);
      expect(enabled(tester, plus()), isFalse);
      expect(enabled(tester, minus()), isTrue);
      await host.run(tester, () => host.h.c.setRepeatTimes(1));
      await tester.pumpAndSettle();
      expect(enabled(tester, minus()), isFalse);
      expect(enabled(tester, plus()), isTrue);
    });

    testWidgets('dimmed and inert while stopped', (tester) async {
      final host = await _pump(tester);
      await host.run(tester, () => host.h.c.stop());
      await _open(host, tester);
      final row = _row('Repeat this song 1 more time').first;
      expect(
        tester
            .widget<Opacity>(
              find.descendant(of: row, matching: find.byType(Opacity)).first,
            )
            .opacity,
        lessThan(1),
      );
      expect(enabled(tester, plus()), isFalse);
      expect(enabled(tester, minus()), isFalse);
      await tester.tap(find.text('Repeat this song 1 more time'));
      await tester.pumpAndSettle();
      expect(_times(host), 0);
      expect(find.byType(SelectionRow), findsNWidgets(5), reason: 'stays open');
    });

    testWidgets('a counted repeat on top of repeat all keeps all', (
      tester,
    ) async {
      final host = await _pump(tester);
      await host.run(tester, () => host.h.c.setRepeat(RepeatMode.allShuffled));
      await host.run(tester, () => host.h.c.setRepeatTimes(2));
      await _open(host, tester);
      expect(_rowWidget(tester, _shuffled).selected, isFalse);
      expect(
        _rowWidget(tester, 'Repeat this song 2 more times').selected,
        isTrue,
      );
      await host.tap(tester, find.text(_off));
      await tester.pumpAndSettle();
      expect(_counted, findsNothing);
      expect(_times(host), 0);
    });

    testWidgets('the count goes down on the icon as the loops play', (
      tester,
    ) async {
      final host = await _pump(tester);
      await host.run(tester, () => host.h.c.setRepeatTimes(2));
      expect(find.text('2'), findsOneWidget);
      await host.run(tester, () async {
        final t = host.h.engine.nexts.last!.token;
        host.h.engine.emit(EngineAdvanced(t));
      });
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
    });
  });

  testWidgets('the menu fits a 360 dp screen', (tester) async {
    final host = await _pump(tester, size: const Size(360, 640));
    await _open(host, tester);
    expect(tester.takeException(), isNull);
    final box = tester.getRect(find.byType(SelectionRow).first);
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(360));
    final heights = [
      for (final e in find.byType(SelectionRow).evaluate())
        tester.getSize(find.byWidget(e.widget)).height,
    ];
    expect(heights.every((h) => h >= 48), isTrue, reason: '$heights');
  });
}
