import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/ui/browse/play_actions.dart';
import 'package:kanaru/src/library/ui/menus/menu_action_runner.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_playback_commands.dart';

const _ctx = PlayContext(PlayContextKind.songs);

/// Two buttons: ▶ on tile A and ▶ on tile B, plus a way to remove tile A.
class _Tiles extends ConsumerStatefulWidget {
  const _Tiles();

  @override
  ConsumerState<_Tiles> createState() => _TilesState();
}

class _TilesState extends ConsumerState<_Tiles> {
  bool showA = true;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (showA)
        Builder(
          builder: (context) => TextButton(
            onPressed: () => playScope(
              ref,
              context,
              const SongScope.genre('a'),
              BrowseList.songs,
              _ctx,
            ),
            child: const Text('A'),
          ),
        ),
      Builder(
        builder: (context) => TextButton(
          onPressed: () => playScope(
            ref,
            context,
            const SongScope.genre('b'),
            BrowseList.songs,
            _ctx,
          ),
          child: const Text('B'),
        ),
      ),
      TextButton(
        onPressed: () => setState(() => showA = false),
        child: const Text('remove A'),
      ),
    ],
  );
}

Future<(FakePlaybackCommands, Map<String, Completer<List<TrackId>>>)> _pump(
  WidgetTester tester,
) async {
  final playback = FakePlaybackCommands();
  final reads = <String, Completer<List<TrackId>>>{};
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playbackCommandsProvider.overrideWithValue(playback),
        scopeIdsReaderProvider.overrideWithValue((scope, sort) {
          final key = (scope as GenreSongs).genreKey;
          return (reads[key] = Completer()).future;
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: _Tiles()),
      ),
    ),
  );
  return (playback, reads);
}

/// Plays slowly then fails, so a test can remove the tile in between.
class _FailingLater extends FakePlaybackCommands {
  final Completer<void> release = Completer();

  @override
  Future<void> playTracks(
    List<TrackId> tracks, {
    int startIndex = 0,
    bool shuffle = false,
    required PlayContext context,
  }) async {
    await release.future;
    throw StateError('boom');
  }
}

class _OneTile extends ConsumerStatefulWidget {
  const _OneTile();

  @override
  ConsumerState<_OneTile> createState() => _OneTileState();
}

class _OneTileState extends ConsumerState<_OneTile> {
  bool shown = true;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (shown)
        Builder(
          builder: (context) => TextButton(
            onPressed: () => playAll(ref, context, const [TrackId(1)], _ctx),
            child: const Text('play'),
          ),
        ),
      TextButton(
        onPressed: () => setState(() => shown = false),
        child: const Text('remove'),
      ),
    ],
  );
}

void main() {
  test('playIds with no ids plays nothing, shuffled or not', () async {
    final playback = FakePlaybackCommands();
    await playIds(playback, const [], _ctx, shuffle: true);
    await playIds(playback, const [], _ctx);
    expect(playback.calls, isEmpty);
  });

  testWidgets('a play that fails after its tile left still shows the toast', (
    tester,
  ) async {
    final playback = _FailingLater();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playbackCommandsProvider.overrideWithValue(playback)],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: _OneTile()),
        ),
      ),
    );
    await tester.tap(find.text('play'));
    await tester.pump();
    await tester.tap(find.text('remove'));
    await tester.pump();
    expect(find.text('play'), findsNothing);
    playback.release.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a slow read for an older tile does not replace the newer play', (
    tester,
  ) async {
    final (playback, reads) = await _pump(tester);
    await tester.tap(find.text('A'));
    await tester.tap(find.text('B'));
    await tester.pump();
    reads['b']!.complete([const TrackId(2)]);
    await tester.pump();
    reads['a']!.complete([const TrackId(1)]);
    await tester.pump();
    expect(
      [for (final c in playback.calls) c.tracks],
      [
        [const TrackId(2)],
      ],
    );
  });

  testWidgets('the play still happens when the tile left during the read', (
    tester,
  ) async {
    final (playback, reads) = await _pump(tester);
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text('remove A'));
    await tester.pump();
    expect(find.text('A'), findsNothing);
    reads['a']!.complete([const TrackId(1)]);
    await tester.pump();
    expect(
      [for (final c in playback.calls) c.tracks],
      [
        [const TrackId(1)],
      ],
    );
  });

  testWidgets('a failed read shows the failure toast', (tester) async {
    final (playback, reads) = await _pump(tester);
    await tester.tap(find.text('A'));
    await tester.pump();
    reads['a']!.completeError(StateError('boom'));
    await tester.pump();
    await tester.pump();
    expect(playback.calls, isEmpty);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('a scope with no songs says there is nothing to play', (
    tester,
  ) async {
    final (playback, reads) = await _pump(tester);
    await tester.tap(find.text('A'));
    await tester.pump();
    reads['a']!.complete(const []);
    await tester.pump();
    await tester.pump();
    expect(playback.calls, isEmpty);
    expect(find.text('Nothing to play'), findsOneWidget);
  });

  testWidgets('a menu Play started after a slow ▶ keeps its queue', (
    tester,
  ) async {
    final (playback, reads) = await _pump(tester);
    await tester.tap(find.text('A'));
    await tester.pump();
    final context = tester.element(find.text('B'));
    final runner = MenuActionRunner(
      ProviderScope.containerOf(context),
      Navigator.of(context, rootNavigator: true).context,
    );
    await runner.run(
      const MenuAction.play([TrackId(9)], shuffle: false, context: _ctx),
    );
    reads['a']!.complete([const TrackId(1)]);
    await tester.pump();
    expect(
      [for (final c in playback.calls) c.tracks],
      [
        [const TrackId(9)],
      ],
    );
  });
}
