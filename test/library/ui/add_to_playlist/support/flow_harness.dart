import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/data/playlists/playlist_reads.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playlists/support/playlist_fixtures.dart';
import 'gated_playlist_store.dart';
import 'picker_host.dart';

/// Advances the app until [done] holds. Waits on the condition, not on a
/// number of frames: each round lets the database answer, then pumps a frame.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  String reason = 'condition',
}) async {
  for (var i = 0; i < 3000; i++) {
    if (done()) return;
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    // Small steps: a flow under a 50 ms limit must not time out just because
    // the test advanced the clock in big jumps.
    await tester.pump(const Duration(milliseconds: 1));
  }
  fail('never reached: $reason');
}

/// Lets a dialog or sheet finish its animation while the picker's confirm
/// button spins: `pumpAndSettle` never returns then.
Future<void> settleBusy(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 600));

/// Pumps until [finder] matches something.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) =>
    pumpUntil(tester, () => finder.evaluate().isNotEmpty, reason: 'a widget');

/// A database with [tracks] songs, a real repository behind a
/// [GatedPlaylistStore], and the app around the flow.
class FlowEnv {
  FlowEnv._(this.fx, this.store, this.tracks);

  final PlaylistFixture fx;
  final GatedPlaylistStore store;
  final List<TrackId> tracks;

  /// The flow started by [start].
  Future<void>? flow;

  /// Whether the flow started by [start] has ended.
  bool ended = false;

  static Future<FlowEnv> open(WidgetTester tester, {int tracks = 3}) async {
    late FlowEnv env;
    await tester.runAsync(() async {
      final fx = await PlaylistFixture.open();
      env = FlowEnv._(
        fx,
        GatedPlaylistStore(fx.db, now: () => fx.clock),
        await fx.tracks(tracks),
      );
    });
    addTearDown(resetAddToPlaylistGuard);
    return env;
  }

  /// Runs [body] on the real event loop (database work).
  Future<T> db<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  /// Creates a playlist holding [tracks] and returns its uid.
  Future<String> playlist(
    WidgetTester tester,
    String name, [
    List<TrackId> tracks = const [],
  ]) => db(tester, () async {
    fx.clock += 100;
    return store.createPlaylist(name: name, tracks: tracks);
  });

  Future<List<int>> held(WidgetTester tester, String uid) =>
      db(tester, () => fx.liveTracks(uid));

  AddToPlaylistRequest request([List<TrackId>? tracks]) =>
      AddToPlaylistRequest(tracks: tracks ?? this.tracks, sourceLabel: 'Album');

  List<Override> get overrides => [
    appDatabaseProvider.overrideWithValue(fx.db),
    playlistStoreProvider.overrideWithValue(store),
  ];

  /// Opens the picker from an "open" button and waits for it to show.
  Future<void> start(
    WidgetTester tester, {
    AddToPlaylistRequest? request,
    Duration? limit,
    Size size = phone,
    String locale = 'en',
    bool waitForPicker = true,
    double textScale = 1,
  }) async {
    await pumpOpener(
      tester,
      size: size,
      locale: locale,
      textScale: textScale,
      overrides: overrides,
      onOpen: (context) {
        ended = false;
        flow = runAddToPlaylist(
          context,
          request ?? this.request(),
          limit: limit,
        ).whenComplete(() => ended = true);
      },
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    if (waitForPicker) {
      await pumpUntilFound(
        tester,
        find.text(_l10n(locale).playlistPickerTitle),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Presses "open" again and waits for the picker.
  Future<void> reopen(WidgetTester tester) async {
    // The previous picker may still be sliding away over the button.
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pump();
    await pumpUntilFound(tester, find.text(l10nOf('en').playlistPickerTitle));
    await tester.pumpAndSettle();
  }

  /// Calls the flow a second time with the first still open (nothing may
  /// open) and returns when that call returned.
  Future<void> flowAgain(WidgetTester tester) {
    final context = tester.element(find.text('open'));
    return runAddToPlaylist(context, request());
  }

  /// Uid of the playlist named [name].
  Future<String> uidOf(WidgetTester tester, String name) => db(
    tester,
    () async =>
        (await loadSummaries(fx.db)).playlists
            .firstWhere((p) => p.name == name)
            .uid,
  );

  /// Whether a playlist named [name] exists.
  Future<bool> exists(WidgetTester tester, String name) => db(
    tester,
    () async =>
        (await loadSummaries(fx.db)).playlists.any((p) => p.name == name),
  );

  /// Deletes the row of [track].
  Future<void> deleteTrack(WidgetTester tester, TrackId track) => db(
    tester,
    () =>
        fx.db.customStatement('DELETE FROM tracks WHERE id = ?', [track.value]),
  );

  /// Makes [track] missing from the library.
  Future<void> markMissing(WidgetTester tester, TrackId track) => db(
    tester,
    () => fx.db.customStatement(
      "UPDATE tracks SET status = 'missing', missing_since = 1 WHERE id = ?",
      [track.value],
    ),
  );

  AppLocalizations _l10n(String locale) => l10nOf(locale);
}

/// The row of [text] in a picker.
Finder row(String text) => find.widgetWithText(SelectionRow, text);

/// Whether the row of [text] is ticked, read from its semantics.
bool ticked(WidgetTester tester, String text) {
  final handle = tester.ensureSemantics();
  try {
    return isSemantics(
      isChecked: true,
      hasCheckedState: true,
    ).matches(tester.getSemantics(row(text)), {});
  } finally {
    handle.dispose();
  }
}

Future<void> tick(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pump();
}

/// Taps the confirm button labelled [label].
Future<void> pressAdd(WidgetTester tester, [String label = 'Add']) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

/// Whether [text] is on screen and reachable (not covered by a sheet or a
/// scrim): a toast under the picker does not count.
bool toast(String text) => find.text(text).hitTestable().evaluate().isNotEmpty;

/// A message shown in the picker's footer; never a snack bar.
bool footerError(String text) =>
    toast(text) && find.byType(SnackBar).evaluate().isEmpty;

/// Answers the question: taps [option] and confirms.
Future<void> answerAlready(
  WidgetTester tester,
  AppLocalizations l10n,
  String option,
) async {
  await tester.tap(find.text(option));
  await tester.pump();
  await tester.tap(find.text(l10n.playlistConfirm));
  await tester.pump();
}

/// Presses Add and waits for the question to show.
Future<void> pressAddAndWaitForQuestion(WidgetTester tester) async {
  await pressAdd(tester);
  await pumpUntilFound(tester, find.text(l10nOf('en').playlistAlreadyTitle));
  await settleBusy(tester);
}
