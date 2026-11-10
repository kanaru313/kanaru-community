// Dev fixture, not a test of the suite (no `_test` suffix). It builds a
// throwaway library and a saved playback session so the app can be run
// against known data:
//
//   KANARU_SEED=1 \
//   XDG_CONFIG_HOME=/tmp/kanaru-lane-b/config \
//   XDG_DATA_HOME=/tmp/kanaru-lane-b/data \
//   XDG_CACHE_HOME=/tmp/kanaru-lane-b/cache \
//   flutter test test/playback/support/seed_lane_b_session.dart
//
// It refuses to run unless all three XDG roots are under /tmp/ (see
// seed_guard.dart). Optional: KANARU_SEED_TRACKS (default 6) and
// KANARU_SEED_ANDROID_ROOT=<dir on the phone> to store that folder as the
// mount root instead of the local one (push the generated files there).
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/foundation/ids/ulid.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/playback/data/queue_repository.dart';
import 'package:path/path.dart' as p;

import '../../database/support/test_db.dart';
import 'seed_guard.dart';

const _sampleRate = 16000;
const _seconds = 45;
const _toneHz = 440;

/// One WAV file holding samples [fromSample, fromSample + count) of a single
/// continuous sine. 45 s at 16 kHz holds a whole number of cycles of 440 Hz,
/// so consecutive files join without a click (gapless check).
Uint8List toneWav(int fromSample, int count) {
  final data = ByteData(44 + count * 2);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + count * 2, Endian.little);
  ascii(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _sampleRate, Endian.little);
  data.setUint32(28, _sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, count * 2, Endian.little);
  for (var i = 0; i < count; i++) {
    final v = sin(2 * pi * _toneHz * (fromSample + i) / _sampleRate) * 6000;
    data.setInt16(44 + i * 2, v.round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  test('seed the playback session', () async {
    final env = Platform.environment;
    final problem = seedEnvironmentProblem(env);
    if (problem != null) fail(problem);

    final count = int.tryParse(env['KANARU_SEED_TRACKS'] ?? '') ?? 6;
    final musicDir = Directory('/tmp/kanaru-lane-b/music')
      ..createSync(recursive: true);
    final mountRoot = env['KANARU_SEED_ANDROID_ROOT'] ?? musicDir.path;
    final perFile = _sampleRate * _seconds;
    for (var i = 0; i < count; i++) {
      File(p.join(musicDir.path, 'tone-${i + 1}.wav'))
          .writeAsBytesSync(toneWav(i * perFile, perFile));
    }

    final dataDir = Directory(
      p.join(env['XDG_DATA_HOME']!, kanaruDirName),
    )..createSync(recursive: true);
    final configDir = Directory(
      p.join(env['XDG_CONFIG_HOME']!, kanaruDirName),
    )..createSync(recursive: true);
    final db = AppDatabase.file(File(p.join(dataDir.path, 'kanaru.db')));
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sourceUid = newUlid(nowMs: now);
      final source = await addSource(
        db,
        uid: sourceUid,
        name: 'Seed music',
        root: mountRoot,
        now: now,
      );
      await addMount(db, source, root: mountRoot);
      final ids = <TrackId>[];
      for (var i = 0; i < count; i++) {
        final locator = 'tone-${i + 1}.wav';
        final title = 'Tone ${i + 1}';
        ids.add(
          TrackId(
            await upsertTrackSnapshot(
              db,
              db.tracks,
              TracksCompanion.insert(
                uid: trackUid(sourceUid, locator),
                sourceId: source,
                locator: locator,
                relPath: locator,
                title: title,
                titleSearch: Value(title.toLowerCase()),
                artist: const Value('Kanaru Test'),
                durationMs: const Value(_seconds * 1000),
                addedAt: now,
                updatedAt: now,
              ),
            ),
          ),
        );
      }
      final entries = await QueueRepository(db).replace(ids, now);

      final settings = await JsonSettingsStore.open(
        File(p.join(configDir.path, 'settings.json')),
      );
      await settings.write('library.setup_done', true);
      await settings.write('playback.queue.current_entry', entries.first.entryId);
      await settings.write('playback.position_ms', 0);
      await settings.write('playback.shuffle', false);
      await settings.write('playback.repeat', 'off');
      await settings.write('playback.context', {
        'kind': 'songs',
        'ref': null,
        'label': null,
      });
      await settings.flush();
      // ignore: avoid_print
      print('Seeded $count tracks in ${musicDir.path}; database in ${dataDir.path}');
    } finally {
      await db.close();
    }
  });
}
