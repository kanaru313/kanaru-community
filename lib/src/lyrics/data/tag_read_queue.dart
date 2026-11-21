import 'dart:async';

import '../domain/embedded_lyrics.dart';
import 'local_lyrics_read.dart';
import 'local_lyrics_reader.dart';

/// One queued tag read: await [result]; [cancel] drops it while it still
/// waits (a read already running cannot be stopped).
class TagRead {
  TagRead._(this.path, this._queue);

  final String path;
  final TagReadQueue _queue;
  final _done = Completer<EmbeddedLyrics?>();

  /// The tags, a failure, or [LyricsSuperseded] when cancelled while waiting.
  Future<EmbeddedLyrics?> get result => _done.future;

  /// Drops this read if it has not started and returns true; false (and
  /// harmless) when it already runs or finished.
  bool cancel() => _queue._cancel(this);
}

/// One tag read in flight at a time (the native side keeps at most two stuck
/// threads); the newest waiting request runs next. A waiting request is
/// dropped only when its requester cancels it (the provider was disposed),
/// never because a newer request arrived. Every request's future completes
/// (value, failure or [LyricsSuperseded]).
class TagReadQueue {
  TagReadQueue(this._reader);

  final LocalLyricsReader _reader;
  final _pending = <TagRead>[];
  bool _running = false;

  TagRead read(String audioPath) {
    final request = TagRead._(audioPath, this);
    _pending.add(request);
    if (!_running) unawaited(_pump());
    return request;
  }

  bool _cancel(TagRead request) {
    if (!_pending.remove(request)) return false;
    request._done.completeError(const LyricsSuperseded());
    return true;
  }

  Future<void> _pump() async {
    _running = true;
    try {
      while (_pending.isNotEmpty) {
        final next = _pending.removeLast();
        try {
          next._done.complete(await _reader.readTag(next.path));
        } on Object catch (e, st) {
          next._done.completeError(e, st);
        }
      }
    } finally {
      _running = false;
    }
  }
}
