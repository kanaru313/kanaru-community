import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/ai/state/tool_env_provider.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../lyrics/support/lyrics_harness.dart';

void main() {
  late LyricsHarness h;
  setUp(() => h = LyricsHarness());
  tearDown(() => h.dispose());

  final lyricsPortProvider = Provider<LyricsPort>(
    (ref) => buildToolEnv(ref).lyrics,
  );

  Future<TrackId> song() async {
    final id = await h.addTrackRow('a.flac');
    await (h.db.update(h.db.tracks)..where((t) => t.id.equals(id.value))).write(
      const TracksCompanion(title: Value('Song'), artist: Value('Artist')),
    );
    return id;
  }

  test('a song without lyrics reads as absent, never throws', () async {
    final id = await song();
    h.play(id);
    final port = h.container.read(lyricsPortProvider);
    final r = await port.read(id.value);
    expect(r, isA<LyricsAbsent>());
  });
}
