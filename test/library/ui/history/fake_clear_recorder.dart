import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/playback/data/play_log_writer.dart';
import 'package:kanaru/src/playback/state/listen_recorder.dart';

/// A recorder whose clears are scripted: it records the bounds, can wait on a
/// [gate], reports `clearing` like the real one and answers [result].
class FakeClearRecorder extends ListenRecorder {
  FakeClearRecorder(AppDatabase db)
    : super(writer: PlayLogWriter(db), deviceId: () => 'dev');

  final calls = <({int? from, int? to})>[];

  /// What a clear answers: how many plays went, null = the delete failed.
  int? result = 0;

  /// While set, a clear waits for it.
  Completer<void>? gate;
  final _clearing = ValueNotifier<bool>(false);

  /// Flips the flag as a clear started elsewhere would.
  set externalClear(bool value) => _clearing.value = value;

  @override
  ValueListenable<bool> get clearing => _clearing;

  @override
  Future<int?> clearHistory({int? from, int? to}) async {
    calls.add((from: from, to: to));
    _clearing.value = true;
    try {
      await gate?.future;
      return result;
    } finally {
      _clearing.value = false;
    }
  }
}
