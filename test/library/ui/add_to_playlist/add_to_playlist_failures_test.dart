import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import 'support/flow_harness.dart';
import 'support/picker_host.dart';

const _limit = Duration(milliseconds: 50);

void main() {
  final en = l10nOf('en');
  final title = find.text(en.playlistPickerTitle);

  /// The picker opens again after a failure: the guard was released.
  Future<void> expectOpensAgain(WidgetTester tester, FlowEnv env) async {
    await env.reopen(tester);
    expect(title, findsOneWidget);
    await tester.tap(find.text(en.playlistCancel));
    await pumpUntil(tester, () => env.ended);
  }

  testWidgets('a song removed between the read and the write: retried once '
      'and written once', (tester) async {
    final env = await FlowEnv.open(tester);
    final a = await env.playlist(tester, 'A');
    await env.start(tester);
    env.store.addArgumentErrors = 1;

    await tick(tester, 'A');
    await pressAdd(tester);
    await pumpUntil(tester, () => toast('Added 3 songs to “A”'));

    expect(env.store.addCalls, 2);
    expect((await env.held(tester, a)).length, 3);
  });

  testWidgets('the retry fails too: toast, picker open with its ticks, '
      'nothing written', (tester) async {
    final env = await FlowEnv.open(tester);
    final a = await env.playlist(tester, 'A');
    await env.start(tester);
    env.store.addArgumentErrors = 2;

    await tick(tester, 'A');
    await pressAdd(tester);
    await pumpUntil(tester, () => footerError(en.playlistAddFailed));

    expect(env.store.addCalls, 2);
    expect(await env.held(tester, a), isEmpty);
    expect(title, findsOneWidget);
    expect(ticked(tester, 'A'), isTrue);
    await tester.tap(find.text(en.playlistCancel));
    await pumpUntil(tester, () => env.ended);
    await expectOpensAgain(tester, env);
  });

  testWidgets('a read before the write never answers: timed-out toast, '
      'picker open, Cancel works, a second open works', (tester) async {
    final env = await FlowEnv.open(tester);
    final a = await env.playlist(tester, 'A');
    await env.start(tester, limit: _limit);
    env.store.countGate = Completer<void>();

    await tick(tester, 'A');
    await pressAdd(tester);
    await pumpUntil(tester, () => footerError(en.plAddTimedOut));

    expect(title, findsOneWidget);
    expect(ticked(tester, 'A'), isTrue);
    expect(await env.held(tester, a), isEmpty);
    env.store.countGate = null;
    await tester.tap(find.text(en.playlistCancel));
    await pumpUntil(tester, () => env.ended);
    await expectOpensAgain(tester, env);
  });

  testWidgets('a read before the write throws: failed toast, picker open', (
    tester,
  ) async {
    final env = await FlowEnv.open(tester);
    await env.playlist(tester, 'A');
    await env.start(tester);
    env.store.countErrors.add(StateError('database is locked'));

    await tick(tester, 'A');
    await pressAdd(tester);
    await pumpUntil(tester, () => footerError(en.playlistAddFailed));

    expect(title, findsOneWidget);
    expect(ticked(tester, 'A'), isTrue);
    await tester.tap(find.text(en.playlistCancel));
    await pumpUntil(tester, () => env.ended);
    await expectOpensAgain(tester, env);
  });

  testWidgets('the write never answers: "not confirmed" toast, picker '
      'closed, guard released; the late write lands once and is logged', (
    tester,
  ) async {
    final records = <LogRecord>[];
    final sub = Logger.root.onRecord.listen(records.add);
    addTearDown(sub.cancel);
    final env = await FlowEnv.open(tester);
    final a = await env.playlist(tester, 'A');
    await env.start(tester, limit: _limit);
    final gate = env.store.addGate = Completer<void>();

    await tick(tester, 'A');
    await pressAdd(tester);
    await pumpUntil(tester, () => toast(en.plAddNotConfirmed));
    await pumpUntil(tester, () => env.ended);
    await tester.pumpAndSettle();

    expect(
      title,
      findsNothing,
      reason: 'closed, so Add cannot be pressed twice',
    );
    expect(env.store.addCalls, 1);

    gate.complete();
    await pumpUntil(
      tester,
      () => records.any((r) => r.message.contains('finished after the limit')),
      reason: 'the late result is logged',
    );
    expect((await env.held(tester, a)).length, 3);
    expect(env.store.addCalls, 1);

    env.store.addGate = null;
    await expectOpensAgain(tester, env);
  });

  testWidgets('the retry write never answers: "not confirmed", picker closed, '
      'the late write lands once', (tester) async {
    final env = await FlowEnv.open(tester);
    final a = await env.playlist(tester, 'A');
    await env.start(tester, limit: _limit);
    env.store.addArgumentErrors = 1;
    final gate = env.store.addGate = Completer<void>();

    await tick(tester, 'A');
    await pressAdd(tester);
    await pumpUntil(tester, () => toast(en.plAddNotConfirmed));
    await pumpUntil(tester, () => env.ended);
    await tester.pumpAndSettle();

    expect(title, findsNothing);
    expect(env.store.addCalls, 2);
    gate.complete();
    await pumpUntil(tester, () => env.store.addCalls == 2);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect((await env.held(tester, a)).length, 3);
    expect(env.store.addCalls, 2);

    env.store.addGate = null;
    await expectOpensAgain(tester, env);
  });

  group(
    'on the test phone size and 200 % text the message is read in full',
    () {
      final cases = <String, Future<String> Function(WidgetTester, FlowEnv)>{
        'failed': (tester, env) async {
          env.store.countErrors.add(StateError('database is locked'));
          return en.playlistAddFailed;
        },
        'timed out': (tester, env) async {
          env.store.countGate = Completer<void>();
          return en.plAddTimedOut;
        },
        'playlist gone': (tester, env) async {
          final uid = await env.uidOf(tester, 'A');
          await env.db(tester, () => env.store.deletePlaylist(uid));
          return en.playlistAddedGone(1);
        },
        'songs gone': (tester, env) async {
          for (final t in env.tracks) {
            await env.deleteTrack(tester, t);
          }
          return en.plAddSongsGone;
        },
      };
      for (final e in cases.entries) {
        testWidgets(e.key, (tester) async {
          final env = await FlowEnv.open(tester);
          await env.playlist(tester, 'A');
          // Taller window: the test font is twice as wide as the real one, so
          // the note beside the buttons wraps to many lines at 200 %.
          await env.start(
            tester,
            // The test phone size in dp (392 x 873).
            size: const Size(392, 873),
            limit: _limit,
            textScale: 2,
          );
          final text = await e.value(tester, env);

          // At 200 % the list is short: bring the row into view first.
          await tester.scrollUntilVisible(find.text('A'), 100);
          await tester.ensureVisible(find.text('A'));
          await tester.pump();
          await tick(tester, 'A');
          await pressAdd(tester);
          await pumpUntil(tester, () => footerError(text));

          expect(tester.takeException(), isNull);
          expect(find.text(text).hitTestable(), findsOneWidget);
        });
      }
    },
  );

  testWidgets('ticking back to the failing set does not bring the message '
      'back', (tester) async {
    final env = await FlowEnv.open(tester);
    await env.playlist(tester, 'A');
    await env.playlist(tester, 'B');
    await env.start(tester);
    env.store.countErrors.add(StateError('database is locked'));

    await tick(tester, 'A');
    await pressAdd(tester);
    await pumpUntil(tester, () => footerError(en.playlistAddFailed));
    await tick(tester, 'B');
    await tester.pump();
    await tick(tester, 'B');
    expect(find.text(en.playlistAddFailed), findsNothing);
  });

  testWidgets('the message goes away when the ticks change', (tester) async {
    final env = await FlowEnv.open(tester);
    await env.playlist(tester, 'A');
    await env.playlist(tester, 'B');
    await env.start(tester);
    env.store.countErrors.add(StateError('database is locked'));

    await tick(tester, 'A');
    await pressAdd(tester);
    await pumpUntil(tester, () => footerError(en.playlistAddFailed));
    await tick(tester, 'B');
    expect(find.text(en.playlistAddFailed), findsNothing);
    expect(find.text(en.playlistPickerSelected(2)), findsOneWidget);
  });

  testWidgets('loading never answers: toast, no picker, guard released', (
    tester,
  ) async {
    final env = await FlowEnv.open(tester);
    env.store.watchGate = Completer<void>();
    await env.start(tester, limit: _limit, waitForPicker: false);

    await pumpUntil(tester, () => toast(en.plAddTimedOut));
    await pumpUntil(tester, () => env.ended);
    expect(title, findsNothing);

    env.store.watchGate = null;
    await expectOpensAgain(tester, env);
  });

  testWidgets('loading the counts throws: failed toast, no picker', (
    tester,
  ) async {
    final env = await FlowEnv.open(tester);
    env.store.countErrors.add(StateError('database is locked'));
    await env.start(tester, waitForPicker: false);

    await pumpUntil(tester, () => toast(en.playlistAddFailed));
    await pumpUntil(tester, () => env.ended);
    expect(title, findsNothing);
    await expectOpensAgain(tester, env);
  });

  testWidgets('a second request while one is open is ignored', (tester) async {
    final env = await FlowEnv.open(tester);
    await env.start(tester);
    await tester.pumpAndSettle();

    final second = env.flowAgain(tester);
    await second;
    expect(title, findsOneWidget, reason: 'still one picker');
  });

  testWidgets('a lookup that throws before the first await: failed toast, '
      'nothing escapes, guard released', (tester) async {
    // No ProviderScope above the button, so the container lookup throws.
    final request = AddToPlaylistRequest(
      tracks: [TrackId(1)],
      sourceLabel: 'Album',
    );
    Future<void>? running;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => running = showAddToPlaylist(context, request),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    final records = <LogRecord>[];
    final sub = Logger.root.onRecord.listen(records.add);
    addTearDown(sub.cancel);

    await tester.tap(find.text('open'));
    await running;
    await tester.pump();

    expect(find.text(en.playlistAddFailed), findsOneWidget);
    expect(records.any((r) => r.level >= Level.SEVERE), isTrue);
    expect(tester.takeException(), isNull);
  });
}
