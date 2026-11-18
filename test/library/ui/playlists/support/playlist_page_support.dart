import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/ui/playlists/playlist_page.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/fake_playback_commands.dart';
import 'playlist_menu_support.dart';
import 'playlist_ui_harness.dart';

final List<ProviderContainer> _containers = [];

/// [uiTest] for the page: the tree goes and the containers are disposed
/// before the final drain, so the throttled queries leave no timer.
void pageTest(String description, Future<void> Function(WidgetTester t) body) =>
    testWidgets(description, (t) async {
      _containers.clear();
      await body(t);
      await t.pumpWidget(const SizedBox());
      for (final c in _containers) {
        c.dispose();
      }
      await drain(t);
    });

/// Pumps the real [PlaylistPage] for `/playlists/<uid>` above a host route,
/// over the real repository. [pageWidth] narrows the page itself inside a
/// wider window (the wide layout is chosen by the page's width).
Future<PlaylistUiHarness> pumpPlaylistPage(
  WidgetTester t, {
  required String uid,
  double width = 360,
  double height = 800,
  double textScale = 1,
  double? pageWidth,
  FakePlaybackCommands? playback,
  List<Override> overrides = const [],
}) async {
  final h = await PlaylistUiHarness.pump(
    t,
    width: width,
    textScale: textScale,
    pageBuilder: (_, uid) {
      final page = Scaffold(body: PlaylistPage(uid: uid));
      return pageWidth == null
          ? page
          : Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: pageWidth, child: page),
            );
    },
    overrides: [
      fileManagerProvider.overrideWithValue(NoFileManager()),
      playbackCommandsProvider.overrideWithValue(
        playback ?? FakePlaybackCommands(),
      ),
      ...overrides,
    ],
  );
  _containers.add(h.container);
  t.view.physicalSize = Size(width, height);
  await t.pump();
  unawaited(h.router.push<void>('/playlists/$uid'));
  await settlePlaylistPage(t);
  return h;
}

/// Lets database answers (real time) arrive and routes animate.
Future<void> settlePlaylistPage(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await t.pump(const Duration(milliseconds: 600));
  }
  await t.pumpAndSettle();
}

/// Creates playlist [name] with the given tracks (a name ending in `*` is a
/// missing file) and returns its uid.
Future<String> seedTracks(
  WidgetTester t,
  PlaylistUiHarness h,
  List<String> titles, {
  String name = 'Mix',
  String description = '',
}) async {
  return (await t.runAsync(() async {
    final tracks = <TrackId>[
      for (final title in titles)
        await h.fixture.track(
          title.replaceAll('*', ''),
          status: title.endsWith('*') ? TrackStatus.missing : null,
        ),
    ];
    return h.fixture.repo.createPlaylist(
      name: name,
      description: description,
      tracks: tracks,
    );
  }))!;
}

/// Adds [titles] (tracks that already exist by name are not duplicated: new
/// ones are created) to Favorites.
Future<void> seedFavorites(
  WidgetTester t,
  PlaylistUiHarness h,
  List<String> titles,
) async {
  await t.runAsync(() async {
    final tracks = [for (final title in titles) await h.fixture.track(title)];
    await h.store.addToPlaylists(
      tracks: tracks,
      playlistUids: [PlaylistUids.favorites],
    );
  });
}

AppLocalizations pageL10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(PlaylistPage)));

/// Titles of [names] in the order they appear on screen, top to bottom.
List<String> rowOrder(WidgetTester t, List<String> names) {
  final shown = [
    for (final n in names)
      if (find.text(n).evaluate().isNotEmpty) n,
  ];
  shown.sort(
    (a, b) => t
        .getTopLeft(find.text(a).first)
        .dy
        .compareTo(t.getTopLeft(find.text(b).first).dy),
  );
  return shown;
}

/// The detail the page shows now.
PlaylistDetail? shownDetail(PlaylistUiHarness h, String uid) =>
    h.container.read(playlistPageProvider(uid)).detail.value;
