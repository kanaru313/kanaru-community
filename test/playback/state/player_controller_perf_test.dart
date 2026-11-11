import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../support/controller_harness.dart';

void main() {
  test('playTracks with 20 000 entries stays within the debug bound', () async {
    final h = await Harness.create(tracks: 1);
    addTearDown(h.close);
    final ids = List.filled(20000, h.tracks.first);
    for (final shuffle in [false, true]) {
      // Best of three: the machine is shared and the bound is for debug mode.
      final times = <int>[];
      for (var run = 0; run < 3; run++) {
        final sw = Stopwatch()..start();
        await h.c.playTracks(ids, shuffle: shuffle, context: ctx);
        times.add(sw.elapsedMilliseconds);
      }
      expect(
        times.reduce(min),
        lessThan(15000),
        reason: 'shuffle $shuffle: $times',
      );
      expect(h.c.queueState.length, 20000);
    }
    await h.settle();
  });
}
