import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_entries.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/ui_host.dart';
import 'sleep_timer_modal_host.dart';

const _desktop = Size(1300, 800);

/// Entries on a desktop-size window, with a stand-in for the ⋮ button the
/// ring button falls back to.
class _Host {
  _Host(this.more);

  late UiHost ui;
  final FocusNode more;
  int shellEscapes = 0;
  int parentBuilds = 0;

  /// Whether the desktop entry is in the tree (a narrowing bar drops it).
  final entryShown = ValueNotifier<bool>(true);

  FakeSleepTimer get timer =>
      ui.container.read(sleepTimerProvider.notifier) as FakeSleepTimer;
}

Future<_Host> _pump(
  WidgetTester tester, {
  bool play = true,
  bool ring = false,
  SleepTimerOpener? opener,
}) async {
  final more = FocusNode(debugLabel: 'more');
  addTearDown(more.dispose);
  final host = _Host(more);
  addTearDown(host.entryShown.dispose);
  host.ui = await pumpWithPlayer(
    tester,
    CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            host.shellEscapes++,
      },
      child: Builder(
        builder: (context) {
          host.parentBuilds++;
          return Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: host.entryShown,
                builder: (_, shown, _) => shown
                    ? SleepTimerDesktopEntry(opener: opener)
                    : const SizedBox(),
              ),
              if (ring) SleepTimerRingButton(fallbackFocus: more),
              const SleepTimerMenuLabel(),
              Focus(
                focusNode: more,
                child: const SizedBox(width: 24, height: 24),
              ),
            ],
          );
        },
      ),
    ),
    play: play,
    size: _desktop,
    overrides: [
      sleepTimerProvider.overrideWith(FakeSleepTimer.new),
      ...sleepEstimates(),
    ],
  );
  return host;
}

Finder get _pill => find.byType(KPill);
Finder get _icon => find.byWidgetPredicate(
  (w) => w is KIconButton && w.icon == KIcons.sleepTimer,
);
Finder get _modal => find.byType(KStartArea);
Finder get _ring => find.byType(KProgressRingIcon);

FocusNode _pillNode(WidgetTester tester) =>
    tester.widget<KPill>(_pill).focusNode!;

void main() {
  group('desktop entry', () {
    testWidgets('off: the icon says "Sleep timer"; no pill', (tester) async {
      await _pump(tester);
      final button = tester.widget<KIconButton>(_icon);
      expect(button.tooltip, 'Sleep timer');
      expect(button.onPressed, isNotNull);
      expect(_pill, findsNothing);
    });

    testWidgets('no track: no entry', (tester) async {
      await _pump(tester, play: false);
      expect(_icon, findsNothing);
      expect(_pill, findsNothing);
    });

    for (final (name, state, label, tooltip, spoken, held) in [
      (
        'minutes',
        runningMinutes(),
        '23:41',
        'Sleep timer: Sleep in 23:41',
        'Sleep timer: 24 minutes left',
        false,
      ),
      (
        'minutes, counting paused',
        runningMinutes(held: true),
        '23:41',
        'Sleep timer: Counting paused · 23:41 left',
        'Sleep timer: 24 minutes left (counting paused)',
        true,
      ),
      (
        'tracks',
        runningTracks(),
        '3 tracks',
        'Sleep timer: Pause after 3 tracks',
        'Sleep timer: 3 tracks left',
        false,
      ),
      (
        'end of track',
        runningEndOf(SleepTimerMode.endOfTrack),
        'Track',
        'Sleep timer: Pause at the end of this track',
        'Sleep timer: end of this track',
        false,
      ),
      (
        'end of album',
        runningEndOf(SleepTimerMode.endOfAlbum),
        'Album',
        'Sleep timer: Pause at the end of this album',
        'Sleep timer: end of this album',
        false,
      ),
      (
        'end of queue',
        runningEndOf(SleepTimerMode.endOfQueue),
        'Queue',
        'Sleep timer: Pause at the end of the queue',
        'Sleep timer: end of the queue',
        false,
      ),
    ]) {
      testWidgets('running, $name: label, seconds tooltip, minute semantics', (
        tester,
      ) async {
        final host = await _pump(tester);
        final handle = tester.ensureSemantics();
        host.timer.set(state);
        await tester.pump();
        expect(_icon, findsNothing);
        final pill = tester.widget<KPill>(_pill);
        expect(pill.label, label);
        expect(pill.tooltip, tooltip);
        expect(pill.semanticLabel, spoken);
        expect(pill.held, held);
        expect(find.bySemanticsLabel(spoken), findsOneWidget);
        handle.dispose();
      });
    }

    testWidgets('the pill keeps a width for the widest label of the run', (
      tester,
    ) async {
      final host = await _pump(tester);
      host.timer.set(runningMinutes());
      await tester.pump();
      expect(tester.widget<KPill>(_pill).widestLabel, '00:00');
      host.timer.set(
        runningMinutes(remaining: const Duration(hours: 1, minutes: 5)),
      );
      await tester.pump();
      expect(tester.widget<KPill>(_pill).widestLabel, '0:00:00');
    });

    testWidgets('a tick changes the label; the rest of the screen is idle', (
      tester,
    ) async {
      final host = await _pump(tester);
      final handle = tester.ensureSemantics();
      host.timer.set(runningMinutes());
      await tester.pump();
      final builds = host.parentBuilds;
      for (var s = 40; s >= 38; s--) {
        host.timer.set(
          runningMinutes(remaining: Duration(minutes: 23, seconds: s)),
        );
        await tester.pump();
        expect(tester.widget<KPill>(_pill).label, '23:$s');
      }
      // Seconds change the text, minutes the spoken label.
      expect(find.bySemanticsLabel('Sleep timer: 24 minutes left'), findsOne);
      expect(host.parentBuilds, builds);
      handle.dispose();
    });

    testWidgets('the entry has the whole timer off and on again', (
      tester,
    ) async {
      final host = await _pump(tester);
      host.timer.set(runningMinutes());
      await tester.pump();
      host.timer.set(const SleepTimerState.off());
      await tester.pump();
      expect(_pill, findsNothing);
      expect(_icon, findsOneWidget);
    });
  });

  group('desktop entry focus', () {
    testWidgets('icon -> tile with Enter -> the pill has focus', (
      tester,
    ) async {
      final host = await _pump(tester);
      await tester.tap(_icon);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(host.timer.calls, ['startMinutes:45']);
      expect(_modal, findsNothing);
      expect(_pillNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('Tắt from the pill: the icon has focus', (tester) async {
      final host = await _pump(tester);
      host.timer.set(runningMinutes());
      await tester.pump();
      await tester.tap(_pill);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Turn off timer'));
      expect(host.timer.state.active, isFalse);
      expect(
        tester.widget<KIconButton>(_icon).focusNode!.hasPrimaryFocus,
        isTrue,
      );
    });

    testWidgets('Esc closes only the modal and returns to the pill', (
      tester,
    ) async {
      final host = await _pump(tester);
      host.timer.set(runningMinutes());
      await tester.pump();
      await tester.tap(_pill);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_modal, findsNothing);
      expect(host.shellEscapes, 0);
      expect(_pillNode(tester).hasPrimaryFocus, isTrue);
    });

    testWidgets('the queue cleared while the modal is open: no error', (
      tester,
    ) async {
      final host = await _pump(tester);
      await tester.tap(_icon);
      await tester.pumpAndSettle();
      await host.ui.run(tester, host.ui.h.c.clearQueue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_modal, findsNothing);
      expect(_icon, findsNothing);
    });

    testWidgets(
      'the entry leaving the tree while the modal is open: no error',
      (tester) async {
        final host = await _pump(tester);
        await tester.tap(_icon);
        await tester.pumpAndSettle();
        // The bar narrows and drops the entry; the modal stays.
        host.entryShown.value = false;
        await tester.pumpAndSettle();
        expect(_modal, findsWidgets);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a custom opener is used and its result awaited', (
      tester,
    ) async {
      final opened = <String>[];
      await _pump(
        tester,
        opener: (context, returnFocus) async {
          opened.add('open');
          await openSleepTimerModal(context, returnFocus);
          opened.add('closed');
        },
      );
      await tester.tap(_icon);
      await tester.pumpAndSettle();
      expect(opened, ['open']);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(opened, ['open', 'closed']);
    });
  });

  group('ring button', () {
    testWidgets('only while a timer runs', (tester) async {
      final host = await _pump(tester, ring: true);
      expect(_ring, findsNothing);
      host.timer.set(runningMinutes());
      await tester.pump();
      expect(_ring, findsOneWidget);
      host.timer.set(const SleepTimerState.off());
      await tester.pump();
      expect(_ring, findsNothing);
    });

    testWidgets('minutes: a ring of what is left; held; tooltips', (
      tester,
    ) async {
      final host = await _pump(tester, ring: true);
      final handle = tester.ensureSemantics();
      host.timer.set(runningMinutes());
      await tester.pump();
      final ring = tester.widget<KProgressRingIcon>(_ring);
      expect(ring.progress, closeTo(1421 / 2700, 0.001));
      expect(ring.held, isFalse);
      final button = tester.widget<KIconButton>(
        find.ancestor(of: _ring, matching: find.byType(KIconButton)),
      );
      expect(button.tooltip, 'Sleep timer: 23:41 left');
      expect(button.semanticLabel, 'Sleep timer: 24 minutes left');
      expect(
        find.bySemanticsLabel('Sleep timer: 24 minutes left'),
        findsWidgets,
      );
      host.timer.set(runningMinutes(held: true));
      await tester.pump();
      expect(tester.widget<KProgressRingIcon>(_ring).held, isTrue);
      handle.dispose();
    });

    testWidgets('tracks and end-of modes: a dot, no ring', (tester) async {
      final host = await _pump(tester, ring: true);
      for (final state in [
        runningTracks(),
        runningEndOf(SleepTimerMode.endOfAlbum),
      ]) {
        host.timer.set(state);
        await tester.pump();
        expect(tester.widget<KProgressRingIcon>(_ring).progress, isNull);
      }
    });

    testWidgets('a tap opens the modal on the running screen', (tester) async {
      final host = await _pump(tester, ring: true);
      host.timer.set(runningTracks());
      await tester.pump();
      await tester.tap(_ring);
      await tester.pumpAndSettle();
      expect(find.text('Turn off timer'), findsOneWidget);
    });

    testWidgets('Esc returns focus to the ring', (tester) async {
      final host = await _pump(tester, ring: true);
      host.timer.set(runningMinutes());
      await tester.pump();
      await tester.tap(_ring);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      final button = tester.widget<KIconButton>(
        find.ancestor(of: _ring, matching: find.byType(KIconButton)),
      );
      expect(button.focusNode!.hasPrimaryFocus, isTrue);
    });

    testWidgets('Tắt removes the ring and focus goes to the fallback', (
      tester,
    ) async {
      final host = await _pump(tester, ring: true);
      host.timer.set(runningMinutes());
      await tester.pump();
      await tester.tap(_ring);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Turn off timer'));
      expect(_ring, findsNothing);
      expect(tester.takeException(), isNull);
      expect(host.more.hasPrimaryFocus, isTrue);
    });
  });

  group('menu label', () {
    testWidgets('off: plain name; running: ticking, spoken in minutes', (
      tester,
    ) async {
      final host = await _pump(tester);
      final handle = tester.ensureSemantics();
      expect(find.text('Sleep timer'), findsOneWidget);
      host.timer.set(runningMinutes());
      await tester.pump();
      expect(find.text('Sleep timer · 23:41 left'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sleep timer · 24 minutes left'),
        findsOneWidget,
      );
      host.timer.set(
        runningMinutes(remaining: const Duration(minutes: 23, seconds: 40)),
      );
      await tester.pump();
      expect(find.text('Sleep timer · 23:40 left'), findsOneWidget);
      host.timer.set(runningTracks());
      await tester.pump();
      expect(find.text('Sleep timer · 3 tracks left'), findsOneWidget);
      handle.dispose();
    });
  });
}
