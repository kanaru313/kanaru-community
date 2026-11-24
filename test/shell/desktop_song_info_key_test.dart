import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru/src/shell/ui/desktop_song_info_key.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../library/ui/menus/menu_fixtures.dart';
import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

/// A page with a text field, to prove Alt+Enter leaves it alone.
class _Field implements KanaruExtension {
  const _Field();
  @override
  String get id => 'field';
  @override
  void register(ExtensionRegistry r) => r.addRoute(
    GoRoute(
      path: '/field',
      builder: (_, _) => const Scaffold(body: TextField(autofocus: true)),
    ),
  );
}

/// Ids whose info was asked for.
final _asked = <int>[];

Future<ProviderContainer> _pump(WidgetTester tester) async {
  _asked.clear();
  final c = await pumpKanaruApp(
    tester,
    extensions: const [NavFixture(), _Field()],
    overrides: [
      trackInfoProvider.overrideWith((ref, id) {
        _asked.add(id.value);
        return Stream.value(trackInfo(id: id.value));
      }),
    ],
  );
  addTearDown(() => _asked.clear());
  return c;
}

Future<void> _altEnter(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('one selected song opens its info', (tester) async {
    final c = await _pump(tester);
    c.read(librarySelectionProvider.notifier).toggle(const TrackId(7));
    await _altEnter(tester);
    expect(_asked, [7]);
    expect(find.byType(KOverlayPageScope), findsOneWidget);
  });

  testWidgets('no song at all: nothing opens', (tester) async {
    await _pump(tester);
    await _altEnter(tester);
    expect(_asked, isEmpty);
    expect(find.byType(KOverlayPageScope), findsNothing);
  });

  testWidgets('a held key opens one route', (tester) async {
    final c = await _pump(tester);
    c.read(librarySelectionProvider.notifier).toggle(const TrackId(7));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_asked, [7]);
    expect(find.byType(KOverlayPageScope), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    // Lets the selection panel's throttled query finish.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('a focused text field keeps the key', (tester) async {
    final c = await _pump(tester);
    c.read(librarySelectionProvider.notifier).toggle(const TrackId(7));
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/field');
    await tester.pumpAndSettle();
    await _altEnter(tester);
    expect(_asked, isEmpty);
    expect(find.byType(KOverlayPageScope), findsNothing);
  });

  testWidgets('a modal route on top keeps the key', (tester) async {
    final c = await _pump(tester);
    c.read(librarySelectionProvider.notifier).toggle(const TrackId(7));
    unawaited(
      showDialog<void>(
        context: tester.element(find.byType(Scaffold).first),
        builder: (_) => const AlertDialog(title: Text('modal')),
      ),
    );
    await tester.pumpAndSettle();
    await _altEnter(tester);
    expect(_asked, isEmpty);
    expect(find.byType(KOverlayPageScope), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('a lookup that never answers gives up, the next press works', (
    tester,
  ) async {
    final feed = StreamController<TrackInfo?>();
    addTearDown(feed.close);
    var silent = true;
    _asked.clear();
    final c = await pumpKanaruApp(
      tester,
      extensions: const [NavFixture()],
      overrides: [
        trackInfoProvider.overrideWith((ref, id) {
          _asked.add(id.value);
          return silent ? feed.stream : Stream.value(trackInfo(id: id.value));
        }),
      ],
    );
    c.read(librarySelectionProvider.notifier).toggle(const TrackId(7));
    await _altEnter(tester);
    expect(find.byType(KOverlayPageScope), findsNothing);
    await tester.pump(songInfoLookupTimeout + const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    silent = false;
    // The page may prune a selection of unknown songs meanwhile.
    c.read(librarySelectionProvider.notifier).addRange(const [TrackId(7)]);
    await _altEnter(tester);
    expect(_asked, [7, 7]);
    expect(find.byType(KOverlayPageScope), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  group('target order', () {
    ProviderContainer make(NowPlaying now) {
      final c = ProviderContainer(
        overrides: [
          nowPlayingProvider.overrideWith((ref) => Stream.value(now)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    Future<TrackId?> target(ProviderContainer c, List<int> selected) async {
      final sub = c.listen(nowPlayingProvider, (_, _) {});
      await c.read(nowPlayingProvider.future);
      final n = c.read(librarySelectionProvider.notifier);
      for (final id in selected) {
        n.toggle(TrackId(id));
      }
      final id = _target(c);
      sub.close();
      return id;
    }

    const playing = NowPlaying(entryId: 1, trackId: TrackId(9));

    test('one selected beats the playing song', () async {
      expect(await target(make(playing), [4]), const TrackId(4));
    });

    test('two selected fall back to the playing song', () async {
      expect(await target(make(playing), [4, 5]), const TrackId(9));
    });

    test('nothing selected: the playing song', () async {
      expect(await target(make(playing), []), const TrackId(9));
    });

    test('Now Playing open: the playing song beats a selection', () async {
      final c = make(playing);
      c.read(nowPlayingPanelProvider.notifier).open();
      expect(await target(c, [4]), const TrackId(9));
    });

    test('nothing at all: null', () async {
      expect(await target(make(NowPlaying.none), []), isNull);
    });
  });
}

TrackId? _target(ProviderContainer c) => songInfoKeyTarget(c.read);
