import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../../media/domain/cover_colors.dart';
import '../data/cover_colors_rows.dart';

/// Window in which a repeated report of the same key is dropped.
const Duration coverMissDedupe = Duration(seconds: 60);

/// Most keys kept while nobody listens.
const int coverMissBufferLimit = 256;

/// Broadcast of cover keys whose file is gone (cache evicted). `TrackCover`
/// reports; the scanner listens and re-extracts those covers. Keys reported
/// while nobody listens wait (the newest [coverMissBufferLimit]) and go to
/// the first listener.
class CoverMissSink {
  CoverMissSink({DateTime Function()? now}) : _now = now ?? DateTime.now {
    _controller = StreamController<String>.broadcast(
      onListen: () => scheduleMicrotask(_flush),
    );
  }

  final DateTime Function() _now;
  late final StreamController<String> _controller;
  final _lastReported = <String, DateTime>{};
  final _pending = <String>[];

  /// Reports [coverKey]; ignored when it was reported in the last 60 s or
  /// after [close].
  void report(String coverKey) {
    if (_controller.isClosed) return;
    final now = _now();
    _lastReported.removeWhere((_, at) => now.difference(at) >= coverMissDedupe);
    if (_lastReported.containsKey(coverKey)) return;
    _lastReported[coverKey] = now;
    if (_controller.hasListener) {
      _controller.add(coverKey);
      return;
    }
    if (_pending.length >= coverMissBufferLimit) _pending.removeAt(0);
    _pending.add(coverKey);
  }

  void _flush() {
    if (_controller.isClosed || !_controller.hasListener) return;
    final keys = List.of(_pending);
    _pending.clear();
    keys.forEach(_controller.add);
  }

  Stream<String> get misses => _controller.stream;

  Future<void> close() {
    _pending.clear();
    return _controller.close();
  }
}

final coverMissesProvider = Provider<CoverMissSink>((ref) {
  final sink = CoverMissSink();
  ref.onDispose(sink.close);
  return sink;
});

/// Cover colours of one cover (`cover_colors` table); null until the scanner
/// computed them. They tint pages, and the seed of the playing cover's colours
/// drives the app theme (see `playingCoverColorsProvider`).
final coverColorsProvider = StreamProvider.family<CoverColors?, String>(
  (ref, coverKey) => watchCoverColors(ref.watch(appDatabaseProvider), coverKey),
  isAutoDispose: true,
);
