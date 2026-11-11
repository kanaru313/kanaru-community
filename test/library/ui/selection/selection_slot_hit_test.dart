import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/ui/selection/selection_bar.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_playback_commands.dart';
import '../../../database/support/test_db.dart' show addSource;
import '../../browse/support/library_fixture.dart';
import '../support/ui_harness.dart';

/// Songs written by [_app]: more than a 800 px window shows.
const _songs = 16;

/// The whole app on a desktop window, with a few songs. The selection slot is
/// the real one in the real shell.
Future<({ProviderContainer container, FakePlaybackCommands playback})> _app(
  WidgetTester tester, {
  double width = 1280,
}) async {
  final playback = FakePlaybackCommands();
  final container = await pumpKanaruApp(
    tester,
    width: width,
    height: 800,
    playback: playback,
  );
  final db = container.read(appDatabaseProvider);
  final source = await addSource(db);
  for (var i = 1; i <= _songs; i++) {
    await addLibraryTrack(
      db,
      source: source,
      locator: 's$i.flac',
      title: 'Song $i',
      artists: ['Artist'],
      durationMs: 60000,
    );
  }
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/library/songs');
  await tester.pumpAndSettle();
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(seconds: 2));
  }
  return (container: container, playback: playback);
}

Rect _panelRect(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(KSelectionPanel),
        matching: find.byType(Material),
      )
      .first,
);

void main() {
  testWidgets('rows level with the panel, beside it, stay tappable', (
    tester,
  ) async {
    final app = await _app(tester);
    final playback = app.playback;
    final selection = app.container.read(librarySelectionProvider.notifier);
    final listBefore = tester.getRect(find.byType(CustomScrollView).first);

    selection.addRange([TrackId(1), TrackId(2)]);
    selection.setExpanded(true);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(KSelectionPanel), findsOneWidget);
    final panel = _panelRect(tester);
    expect(panel.width, 440);

    // The page keeps its full height: the panel floats over it.
    expect(
      tester.getRect(find.byType(CustomScrollView).first).height,
      listBefore.height,
    );

    // Level with the panel only the panel itself is hit.
    final slot = tester.renderObject(find.byType(LibrarySelectionBar));
    for (final x in [panel.left - 60, panel.right + 60, panel.center.dx]) {
      final path = tester
          .hitTestOnBinding(Offset(x, panel.center.dy))
          .path
          .map((e) => e.target)
          .toList();
      expect(path.contains(slot), x == panel.center.dx, reason: 'x=$x');
    }

    // And a click beside the panel, level with it, reaches the row there.
    for (final x in [panel.left - 60, panel.right + 60]) {
      final before = app.container.read(librarySelectionProvider).ids.length;
      await tester.tapAt(Offset(x, panel.center.dy));
      await tester.pump();
      final after = app.container.read(librarySelectionProvider).ids.length;
      expect(after, isNot(before), reason: 'tap at $x');
    }
    expect(playback.calls, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('the last row scrolls clear of the open panel', (tester) async {
    final app = await _app(tester);
    final selection = app.container.read(librarySelectionProvider.notifier);
    selection.addRange([TrackId(1), TrackId(2), TrackId(3)]);
    selection.setExpanded(true);
    await tester.pump(const Duration(seconds: 1));
    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, -3000),
      3000,
    );
    await tester.pumpAndSettle();
    final panelTop = _panelRect(tester).top;
    final last = tester.getRect(find.text('Song 9'));
    expect(last.bottom, lessThanOrEqualTo(panelTop));
    await unmountApp(tester);
  });

  testWidgets('Ctrl+A works right after a click on the sidebar', (
    tester,
  ) async {
    final app = await _app(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('sidebar')),
        matching: find.text('Songs'),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(seconds: 2));
    }
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(app.container.read(librarySelectionProvider).ids, hasLength(_songs));
    await unmountApp(tester);
  });
}
