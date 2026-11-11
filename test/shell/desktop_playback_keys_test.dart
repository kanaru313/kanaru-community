import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/state/playback_position_provider.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/desktop_now_playing_host.dart';

Future<void> _key(
  WidgetTester tester,
   DesktopHost host,
  LogicalKeyboardKey key, {
  bool repeat = false,
  LogicalKeyboardKey? modifier,
}) async {
  await tester.runAsync(() async {
    if (modifier != null) await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyDownEvent(key);
    if (repeat) await tester.sendKeyRepeatEvent(key);
    await tester.sendKeyUpEvent(key);
    if (modifier != null) await tester.sendKeyUpEvent(modifier);
    await host.h.settle();
  });
  await tester.pump();
}

Future<void> _focusShell(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
  expect(FocusManager.instance.primaryFocus, isNotNull);
  expect(
    FocusManager.instance.primaryFocus,
    isNot(FocusManager.instance.rootScope),
  );
}

Duration _position(DesktopHost host) =>
    host.container.read(playbackPositionProvider).value?.position ??
    Duration.zero;

void main() {
  for (final focused in [false, true]) {
    final mode = focused ? 'with focus in the shell' : 'with nothing focused';
    group('desktop playback keys $mode', () {
      testWidgets('Space toggles play and pause once per press, even on repeat',
          (tester) async {
        final host = await pumpDesktopShell(tester);
        if (focused) await _focusShell(tester);
        expect(host.h.c.intent, PlayIntent.paused);

        await _key(tester, host, LogicalKeyboardKey.space, repeat: true);
        expect(host.h.c.intent, PlayIntent.playing);

        await _key(tester, host, LogicalKeyboardKey.space, repeat: true);
        expect(host.h.c.intent, PlayIntent.paused);
      });

      testWidgets('Left and Right seek by 5 s and repeat while held', (
        tester,
      ) async {
        final host = await pumpDesktopShell(tester);
        host.h.engine.emit(
          EngineLoaded(host.h.loadedToken, const Duration(minutes: 3)),
        );
        await host.letStreamsArrive(tester);
        if (focused) await _focusShell(tester);

        await _key(tester, host, LogicalKeyboardKey.arrowRight);
        expect(_position(host), const Duration(seconds: 5));

        await _key(tester, host, LogicalKeyboardKey.arrowRight, repeat: true);
        expect(_position(host), const Duration(seconds: 15));

        await _key(tester, host, LogicalKeyboardKey.arrowLeft);
        expect(_position(host), const Duration(seconds: 10));

        await _key(tester, host, LogicalKeyboardKey.arrowLeft, repeat: true);
        expect(_position(host), Duration.zero);
      });

      testWidgets('Ctrl+S toggles shuffle once per press', (tester) async {
        final host = await pumpDesktopShell(tester);
        if (focused) await _focusShell(tester);
        expect(host.container.read(shuffleSettingProvider), isFalse);

        await _key(
          tester,
          host,
          LogicalKeyboardKey.keyS,
          modifier: LogicalKeyboardKey.controlLeft,
          repeat: true,
        );
        expect(host.container.read(shuffleSettingProvider), isTrue);

        await _key(
          tester,
          host,
          LogicalKeyboardKey.keyS,
          modifier: LogicalKeyboardKey.controlLeft,
          repeat: true,
        );
        expect(host.container.read(shuffleSettingProvider), isFalse);
      });
    });
  }

  testWidgets(
    'Space while a button has focus plays/pauses without pressing the button; '
    'Enter still presses the button',
    (tester) async {
      var presses = 0;
      final buttonFocus = FocusNode();
      addTearDown(buttonFocus.dispose);
      final host = await pumpDesktopShell(
        tester,
        routes: [
          GoRoute(
            path: '/button',
            builder: (_, _) => Center(
              child: TextButton(
                focusNode: buttonFocus,
                onPressed: () => presses++,
                child: const Text('action'),
              ),
            ),
          ),
        ],
      );
      host.routerRef.go('/button');
      await tester.pumpAndSettle();
      buttonFocus.requestFocus();
      await tester.pump();
      expect(buttonFocus.hasPrimaryFocus, isTrue);

      await _key(tester, host, LogicalKeyboardKey.space, repeat: true);
      expect(host.h.c.intent, PlayIntent.playing);
      expect(presses, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(presses, 1);
    },
  );

  testWidgets('with an empty queue, Space activates a focused button', (
    tester,
  ) async {
    var presses = 0;
    final buttonFocus = FocusNode();
    addTearDown(buttonFocus.dispose);
    final host = await pumpDesktopShell(
      tester,
      play: false,
      routes: [
        GoRoute(
          path: '/button',
          builder: (_, _) => Center(
            child: TextButton(
              focusNode: buttonFocus,
              onPressed: () => presses++,
              child: const Text('action'),
            ),
          ),
        ),
      ],
    );
    host.routerRef.go('/button');
    await tester.pumpAndSettle();
    buttonFocus.requestFocus();
    await tester.pump();

    await _key(tester, host, LogicalKeyboardKey.space);
    expect(presses, 1);
  });

  testWidgets('focused EditableText keeps Space, arrows and Ctrl+S', (
    tester,
  ) async {
    final host = await pumpDesktopShell(
      tester,
      routes: [
        GoRoute(
          path: '/field',
          builder: (_, _) =>
              const Scaffold(body: TextField(autofocus: true)),
        ),
      ],
    );
    host.h.engine.emit(
      EngineLoaded(host.h.loadedToken, const Duration(minutes: 3)),
    );
    await host.letStreamsArrive(tester);
    host.routerRef.go('/field');
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
    );

    final commandsBefore = host.h.engine.commands.length;
    await _key(tester, host, LogicalKeyboardKey.space);
    await _key(tester, host, LogicalKeyboardKey.arrowRight, repeat: true);
    await _key(tester, host, LogicalKeyboardKey.arrowLeft);
    await _key(
      tester,
      host,
      LogicalKeyboardKey.keyS,
      modifier: LogicalKeyboardKey.controlLeft,
    );
    expect(host.h.c.intent, PlayIntent.paused);
    expect(_position(host), Duration.zero);
    expect(host.container.read(shuffleSettingProvider), isFalse);
    expect(host.h.engine.commands.length, commandsBefore);
  });

  group('ignored while a modal, sheet or menu is open', () {
    Future<void> expectIgnored(WidgetTester tester, DesktopHost host) async {
      final commandsBefore = host.h.engine.commands.length;
      await _key(tester, host, LogicalKeyboardKey.space);
      await _key(tester, host, LogicalKeyboardKey.arrowRight, repeat: true);
      await _key(
        tester,
        host,
        LogicalKeyboardKey.keyS,
        modifier: LogicalKeyboardKey.controlLeft,
      );
      expect(host.h.c.intent, PlayIntent.paused);
      expect(_position(host), Duration.zero);
      expect(host.container.read(shuffleSettingProvider), isFalse);
      expect(host.h.engine.commands.length, commandsBefore);
    }

    testWidgets('dialog open', (tester) async {
      final host = await pumpDesktopShell(tester);
      showKDialog<void>(
        tester.element(find.byType(Scaffold).first),
        builder: (_) => const AlertDialog(content: Text('dialog')),
      );
      await tester.pumpAndSettle();
      await expectIgnored(tester, host);
    });

    testWidgets('sheet open', (tester) async {
      final host = await pumpDesktopShell(tester);
      showKSheet<void>(
        tester.element(find.byType(Scaffold).first),
        builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
      );
      await tester.pumpAndSettle();
      await expectIgnored(tester, host);
    });

    testWidgets('MenuAnchor menu open', (tester) async {
      final host = await pumpDesktopShell(tester);
      await tester.tap(find.byTooltip('Stop at the end'));
      await tester.pumpAndSettle();
      expect(find.text('Repeat this song'), findsOneWidget);
      await expectIgnored(tester, host);
    });

    testWidgets('PopupMenuButton menu open', (tester) async {
      final host = await pumpDesktopShell(
        tester,
        routes: [
          GoRoute(
            path: '/popup',
            builder: (_, _) => Center(
              child: PopupMenuButton<int>(
                child: const Text('open popup'),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 1, child: Text('popup item')),
                ],
              ),
            ),
          ),
        ],
      );
      host.routerRef.go('/popup');
      await tester.pumpAndSettle();
      await tester.tap(find.text('open popup'));
      await tester.pumpAndSettle();
      expect(find.text('popup item'), findsOneWidget);
      await expectIgnored(tester, host);
    });
  });

  testWidgets(
    'when the volume Slider has focus, Left and Right adjust the slider '
    'without seeking, while Space and Ctrl+S still control playback',
    (tester) async {
      final host = await pumpDesktopShell(tester);
      host.h.engine.emit(
        EngineLoaded(host.h.loadedToken, const Duration(minutes: 3)),
      );
      await host.run(tester, () => host.h.c.setVolume(50));
      await host.letStreamsArrive(tester);

      final sliderFocusNode = tester
          .widget<Focus>(
            find
                .descendant(
                  of: find.byType(Slider),
                  matching: find.byType(Focus),
                )
                .last,
          )
          .focusNode!;
      sliderFocusNode.requestFocus();
      await tester.pump();
      expect(sliderFocusNode.hasPrimaryFocus, isTrue);

      final initialVolume = host.container.read(volumeSettingProvider);
      expect(initialVolume, 50);

      await _key(tester, host, LogicalKeyboardKey.arrowRight);
      expect(host.container.read(volumeSettingProvider), greaterThan(50));
      expect(
        _position(host),
        Duration.zero,
        reason: 'slider consumed ArrowRight so the track did not seek',
      );

      final afterRight = host.container.read(volumeSettingProvider);
      await _key(tester, host, LogicalKeyboardKey.arrowLeft);
      expect(host.container.read(volumeSettingProvider), lessThan(afterRight));
      expect(_position(host), Duration.zero);

      await _key(tester, host, LogicalKeyboardKey.space);
      expect(host.h.c.intent, PlayIntent.playing);
      await _key(
        tester,
        host,
        LogicalKeyboardKey.keyS,
        modifier: LogicalKeyboardKey.controlLeft,
      );
      expect(host.container.read(shuffleSettingProvider), isTrue);
    },
  );
}
