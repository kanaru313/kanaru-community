import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist.dart';
import 'package:material_ui/material_ui.dart';

import 'support/flow_harness.dart';
import 'support/picker_host.dart';

Future<void> _newPlaylist(WidgetTester tester, String name) async {
  await tick(tester, 'New playlist…');
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, name);
  await tester.tap(find.text(l10nOf('en').playlistPickerNewConfirm));
  await tester.pumpAndSettle();
}

void main() {
  final en = l10nOf('en');
  final title = find.text(en.playlistPickerTitle);

  testWidgets('one song into one playlist: appended, toast names it', (
    tester,
  ) async {
    final env = await FlowEnv.open(tester);
    final a = await env.playlist(tester, 'Chill', [env.tracks[1]]);
    await env.start(tester, request: env.request([env.tracks[0]]));

    await tick(tester, 'Chill');
    await pressAdd(tester);
    await pumpUntil(tester, () => toast('Added 1 song to “Chill”'));
    await pumpUntil(tester, () => env.ended);
    await tester.pumpAndSettle();

    expect(await env.held(tester, a), [
      env.tracks[1].value,
      env.tracks[0].value,
    ]);
    expect(title, findsNothing);
  });

  testWidgets('three songs into two playlists and a new one', (tester) async {
    final env = await FlowEnv.open(tester);
    final a = await env.playlist(tester, 'A');
    final b = await env.playlist(tester, 'B');
    await env.start(tester);

    await tick(tester, 'A');
    await tick(tester, 'B');
    await _newPlaylist(tester, 'Road trip');
    await pressAdd(tester, 'Add to 3 playlists');
    await pumpUntil(
      tester,
      () => toast('Added 3 songs to 3 playlists (1 new)'),
    );

    final all = [for (final t in env.tracks) t.value];
    expect(await env.held(tester, a), all);
    expect(await env.held(tester, b), all);
    expect(await env.held(tester, await env.uidOf(tester, 'Road trip')), all);
  });

  testWidgets('a new playlist that was typed and then cancelled is not '
      'created', (tester) async {
    final env = await FlowEnv.open(tester);
    await env.start(tester);

    await _newPlaylist(tester, 'Road trip');
    await tester.tap(find.text(en.playlistCancel));
    await pumpUntil(tester, () => env.ended);

    expect(await env.exists(tester, 'Road trip'), isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  group('songs a playlist already holds', () {
    // 'Chill' holds [x, t1]; the batch is [t0, t1, t2].
    Future<(FlowEnv, String)> open(WidgetTester tester) async {
      final env = await FlowEnv.open(tester, tracks: 4);
      final chill = await env.playlist(tester, 'Chill', [
        env.tracks[3],
        env.tracks[1],
      ]);
      await env.start(tester, request: env.request(env.tracks.sublist(0, 3)));
      await tick(tester, 'Chill');
      return (env, chill);
    }

    testWidgets('Cancel keeps the picker open with its ticks and writes '
        'nothing; Add asks again', (tester) async {
      final (env, chill) = await open(tester);
      final before = await env.held(tester, chill);

      await pressAddAndWaitForQuestion(tester);
      await tester.tap(find.text(en.playlistCancel).last);
      await tester.pumpAndSettle();

      expect(find.text(en.playlistAlreadyTitle), findsNothing);
      expect(title, findsOneWidget);
      expect(ticked(tester, 'Chill'), isTrue);
      expect(await env.held(tester, chill), before);
      expect(env.store.addCalls, 0);

      await pressAddAndWaitForQuestion(tester);
      expect(env.ended, isFalse);
    });

    testWidgets('only add new songs', (tester) async {
      final (env, chill) = await open(tester);
      await pressAddAndWaitForQuestion(tester);
      await answerAlready(tester, en, en.playlistAlreadySkip);
      await pumpUntil(
        tester,
        () => toast('Added 2 songs to “Chill”, skipped 1'),
      );

      final t = env.tracks;
      expect(await env.held(tester, chill), [
        t[3].value,
        t[1].value,
        t[0].value,
        t[2].value,
      ]);
    });

    testWidgets('drop the old copies', (tester) async {
      final (env, chill) = await open(tester);
      await pressAddAndWaitForQuestion(tester);
      await answerAlready(tester, en, en.playlistAlreadyMove);
      await pumpUntil(
        tester,
        () => toast('Added 3 songs to “Chill”, dropped 1 old copy'),
      );

      final t = env.tracks;
      expect(await env.held(tester, chill), [
        t[3].value,
        t[0].value,
        t[1].value,
        t[2].value,
      ]);
    });

    testWidgets('add all keeps the old copy', (tester) async {
      final (env, chill) = await open(tester);
      await pressAddAndWaitForQuestion(tester);
      await answerAlready(tester, en, en.playlistAlreadyAll);
      await pumpUntil(tester, () => toast('Added 3 songs to “Chill”'));

      final t = env.tracks;
      expect(await env.held(tester, chill), [
        t[3].value,
        t[1].value,
        t[0].value,
        t[1].value,
        t[2].value,
      ]);
    });

    testWidgets('on a 360 px screen the question is a centred dialog', (
      tester,
    ) async {
      await open(tester);
      await pressAddAndWaitForQuestion(tester);

      final dialog = find.ancestor(
        of: find.text(en.playlistAlreadyTitle),
        matching: find.byType(Dialog),
      );
      expect(dialog, findsOneWidget);
      final centre = tester.getCenter(dialog);
      expect(centre.dx, closeTo(180, 1));
      expect(centre.dy, closeTo(320, 60));
    });

    testWidgets('waiting for the answer longer than the limit does not '
        'cancel it', (tester) async {
      final (env, chill) = await open(tester);
      await pressAddAndWaitForQuestion(tester);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text(en.playlistAlreadyTitle), findsOneWidget);
      expect(toast(en.plAddTimedOut), isFalse);

      await answerAlready(tester, en, en.playlistAlreadySkip);
      await pumpUntil(
        tester,
        () => toast('Added 2 songs to “Chill”, skipped 1'),
      );
      expect((await env.held(tester, chill)).length, 4);
    });
  });

  testWidgets('a repeat in the batch: the playlist that holds a song skips '
      'it, the other gets every copy', (tester) async {
    final env = await FlowEnv.open(tester);
    final t = env.tracks;
    final a = await env.playlist(tester, 'A', [t[0]]);
    final b = await env.playlist(tester, 'B');
    await env.start(tester, request: env.request([t[0], t[1], t[0]]));

    await tick(tester, 'A');
    await tick(tester, 'B');
    await pressAdd(tester, 'Add to 2 playlists');
    await pumpUntilFound(tester, find.text(en.playlistAlreadyTitle));
    await settleBusy(tester);
    await answerAlready(tester, en, en.playlistAlreadySkip);
    await pumpUntil(tester, () => env.ended);

    expect(await env.held(tester, a), [t[0].value, t[1].value]);
    expect(await env.held(tester, b), [t[0].value, t[1].value, t[0].value]);
    await pumpUntil(tester, () => toast(en.playlistAddedSummary(2, 2, 0, 1)));
  });

  testWidgets('Favorites holding every song: no question, nothing new', (
    tester,
  ) async {
    final env = await FlowEnv.open(tester);
    await env.db(
      tester,
      () => env.store.addToPlaylists(
        tracks: env.tracks,
        playlistUids: [PlaylistUids.favorites],
      ),
    );
    await env.start(tester);

    await tick(tester, 'Favorites');
    await pressAdd(tester);
    await pumpUntil(
      tester,
      () => toast('Every song is already in “Favorites”'),
    );

    expect(find.text(en.playlistAlreadyTitle), findsNothing);
    expect(await env.held(tester, PlaylistUids.favorites), [
      for (final t in env.tracks) t.value,
    ]);
  });

  group('playlists deleted while the picker is open', () {
    testWidgets('the only ticked one: toast, picker stays, nothing written, '
        'Add off until another row is ticked', (tester) async {
      final env = await FlowEnv.open(tester);
      final a = await env.playlist(tester, 'A');
      await env.playlist(tester, 'B');
      await env.start(tester);

      await tick(tester, 'A');
      await env.db(tester, () => env.store.deletePlaylist(a));
      await pressAdd(tester);
      await pumpUntil(tester, () => footerError(en.playlistAddedGone(1)));

      expect(title, findsOneWidget);
      expect(env.store.addCalls, 0);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.text('Add')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Add',
        ),
      );
      await tick(tester, 'B');
      expect(
        tester.getSemantics(find.text('Add to 2 playlists')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          label: 'Add to 2 playlists',
        ),
      );
      handle.dispose();
    });

    testWidgets('one of two: the live one is written, the toast says the '
        'other is gone', (tester) async {
      final env = await FlowEnv.open(tester);
      final a = await env.playlist(tester, 'A');
      final b = await env.playlist(tester, 'B');
      await env.start(tester);

      await tick(tester, 'A');
      await tick(tester, 'B');
      await env.db(tester, () => env.store.deletePlaylist(b));
      await pressAdd(tester, 'Add to 2 playlists');
      await pumpUntil(
        tester,
        () => toast('Added 3 songs to “A”. ${en.playlistAddedGone(1)}'),
      );
      expect((await env.held(tester, a)).length, 3);
    });
  });

  group('songs that left the library', () {
    testWidgets('one of three is left out and the toast says so', (
      tester,
    ) async {
      final env = await FlowEnv.open(tester);
      final a = await env.playlist(tester, 'A');
      await env.start(tester);

      await env.deleteTrack(tester, env.tracks[2]);
      await tick(tester, 'A');
      await pressAdd(tester);
      await pumpUntil(
        tester,
        () => toast('Added 2 songs to “A”, 1 song no longer in the library'),
      );
      expect(await env.held(tester, a), [
        env.tracks[0].value,
        env.tracks[1].value,
      ]);
    });

    testWidgets('a missing song is added like any other', (tester) async {
      final env = await FlowEnv.open(tester);
      final a = await env.playlist(tester, 'A');
      await env.start(tester);

      await env.markMissing(tester, env.tracks[2]);
      await tick(tester, 'A');
      await pressAdd(tester);
      await pumpUntil(tester, () => toast('Added 3 songs to “A”'));
      expect((await env.held(tester, a)).length, 3);
    });

    testWidgets('all of them: message in the picker, nothing written', (
      tester,
    ) async {
      final env = await FlowEnv.open(tester);
      final a = await env.playlist(tester, 'A');
      await env.start(tester);

      for (final t in env.tracks) {
        await env.deleteTrack(tester, t);
      }
      await tick(tester, 'A');
      await pressAdd(tester);
      await pumpUntil(tester, () => footerError(en.plAddSongsGone));

      expect(title, findsOneWidget);
      expect(await env.held(tester, a), isEmpty);
      expect(env.store.addCalls, 0);
    });
  });

  testWidgets('counts are read again on every open', (tester) async {
    final env = await FlowEnv.open(tester);
    final chill = await env.playlist(tester, 'Chill');
    await env.start(tester);
    expect(
      find.text(en.playlistTrackCount(0)),
      findsNWidgets(2),
      reason: 'Favorites and Chill are empty',
    );

    await tester.tap(find.text(en.playlistCancel));
    await pumpUntil(tester, () => env.ended);
    await env.db(
      tester,
      () => env.store.addToPlaylists(
        tracks: [env.tracks.first],
        playlistUids: [chill],
      ),
    );

    await env.reopen(tester);
    expect(find.text('1 song · has 1 / 3'), findsOneWidget);
  });

  testWidgets('the page that opened the picker is popped meanwhile: the '
      'question, write and toast still happen', (tester) async {
    final env = await FlowEnv.open(tester);
    final a = await env.playlist(tester, 'A', [env.tracks[0]]);
    late Route<void> page;
    await pumpOpener(
      tester,
      overrides: env.overrides,
      onOpen: (context) {
        page = MaterialPageRoute<void>(
          builder: (pageContext) => Scaffold(
            body: TextButton(
              onPressed: () => env.flow = runAddToPlaylist(
                pageContext,
                env.request(),
              ).whenComplete(() => env.ended = true),
              child: const Text('ask'),
            ),
          ),
        );
        Navigator.of(context).push(page);
      },
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ask'));
    await tester.pump();
    await pumpUntilFound(tester, title);
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).removeRoute(page);
    await tester.pump();
    await tick(tester, 'A');
    await pressAddAndWaitForQuestion(tester);
    await answerAlready(tester, en, en.playlistAlreadyAll);
    await pumpUntil(tester, () => toast('Added 3 songs to “A”'));
    expect((await env.held(tester, a)).length, 4);
  });

  testWidgets('the toast shows on the app, not inside a panel with its own '
      'Scaffold', (tester) async {
    final env = await FlowEnv.open(tester);
    await env.playlist(tester, 'A');
    final panel = GlobalKey();
    await pumpOpener(
      tester,
      overrides: env.overrides,
      onOpen: (context) => showModalBottomSheet<void>(
        context: context,
        builder: (_) => ScaffoldMessenger(
          child: Scaffold(
            key: panel,
            body: Builder(
              builder: (panelContext) => TextButton(
                onPressed: () => env.flow = runAddToPlaylist(
                  panelContext,
                  env.request(),
                ).whenComplete(() => env.ended = true),
                child: const Text('ask'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ask'));
    await tester.pump();
    await pumpUntilFound(tester, title);
    await tester.pumpAndSettle();

    await tick(tester, 'A');
    await pressAdd(tester);
    // Found by text, not hit-tested: the panel's own sheet is still open.
    final message = find.text('Added 3 songs to “A”');
    await pumpUntilFound(tester, message);
    expect(message, findsOneWidget);
    expect(
      find.descendant(of: find.byKey(panel), matching: message),
      findsNothing,
    );
  });
}
