import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/screens/settings/ui/playback/playback_settings_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../shell/support/desktop_now_playing_host.dart';

const _path = '/playback-settings';

Finder _sliderAt(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Slider &&
      widget.semanticFormatterCallback?.call(widget.value) == label,
);

/// While the listen-rule sheet (a dialog on the root navigator) is open on the
/// real desktop shell, the shell ignores its playback keys, and the focused
/// slider consumes the arrows: they step the slider and never seek (5 s).
void main() {
  testWidgets('arrows move the focused slider and do not seek the player', (
    tester,
  ) async {
    final host = await pumpDesktopShell(
      tester,
      size: const Size(1280, 1600),
      routes: [
        GoRoute(path: _path, builder: (_, _) => const PlaybackSettingsPage()),
      ],
    );
    await host.run(tester, () async {
      host.h.engine.emit(
        EngineLoaded(host.h.loadedToken, const Duration(minutes: 3)),
      );
    });
    await host.run(tester, () => host.h.c.seek(const Duration(seconds: 10)));
    Future<Duration> position() async =>
        (await tester.runAsync(() => host.h.c.position.first))!.position;
    expect(await position(), const Duration(seconds: 10));

    host.routerRef.go(_path);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Count a listen after'));
    await tester.pumpAndSettle();
    // The shell's own seek bar is a slider too: find the sheet's by value.
    expect(_sliderAt('After 4 minutes of listening'), findsOneWidget);
    expect(_sliderAt('or after 50 % of the track'), findsOneWidget);
    int seeks() =>
        host.h.engine.commands.where((c) => c.startsWith('seek')).length;
    final seeksBefore = seeks();

    // The first slider (time) has the focus: 4 minutes -> 5 minutes -> 4.
    for (final (key, afterMs) in [
      (LogicalKeyboardKey.arrowRight, 300000),
      (LogicalKeyboardKey.arrowLeft, 240000),
      (LogicalKeyboardKey.arrowLeft, 180000),
    ]) {
      await tester.runAsync(() async {
        await tester.sendKeyDownEvent(key);
        await tester.sendKeyUpEvent(key);
        await host.h.settle();
      });
      await tester.pumpAndSettle();
      expect(host.h.settings.read('playback.listen_rule'), {
        'afterMs': afterMs,
        'percent': 50,
      }, reason: '$key');
    }
    await host.letStreamsArrive(tester);
    expect(seeks(), seeksBefore, reason: 'no seek from the arrow keys');
    expect(await position(), const Duration(seconds: 10));
  });
}
