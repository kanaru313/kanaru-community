import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/ui/selection/selection_bar.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../support/fake_playback_commands.dart';
import '../support/detail_fixture.dart';
import '../support/library_harness.dart';

/// The songs page with the selection slot under it and [albums] albums of
/// three songs each ("Album 1 1", ...), shown by title.
Future<LibraryHarness> pumpSelection(
  WidgetTester tester, {
  String initial = '/library/songs',
  double width = 390,
  FakePlaybackCommands? playback,
  int albums = 2,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: initial,
    width: width,
    height: width > 1000 ? 800 : 844,
    playback: playback,
    selectionBar: const LibrarySelectionBar(),
  );
  for (var a = 1; a <= albums; a++) {
    await addAlbum(h, 'Album $a', 'Artist $a', year: 2000 + a);
  }
  await h.settle(tester);
  return h;
}

/// The ids of every track, in title order.
Future<List<TrackId>> allIds(LibraryHarness h) async {
  final rows = await h.db
      .customSelect('SELECT id FROM tracks ORDER BY title_sort')
      .get();
  return [for (final r in rows) TrackId(r.read<int>('id'))];
}

extension SelectionHarness on LibraryHarness {
  LibrarySelection get selection =>
      container.read(librarySelectionProvider.notifier);

  SelectionState get selected => container.read(librarySelectionProvider);
}

/// Lets the 60 ms summary timer and the queries behind it run.
Future<void> pumpSummary(WidgetTester tester, LibraryHarness h) =>
    h.settle(tester, rounds: 2);
