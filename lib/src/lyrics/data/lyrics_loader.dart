import 'dart:async';

import 'package:logging/logging.dart';

import '../../media/domain/track_id.dart';
import '../domain/embedded_lyrics.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_facts.dart';
import 'local_lyrics_read.dart';
import 'local_lyrics_reader.dart';
import 'lyrics_parse_jobs.dart';
import 'lyrics_read_cache.dart';
import 'tag_read_queue.dart';

/// One read shared by every requester of the same key.
class _Flight {
  late Future<LocalLyricsRead> future;
  TagRead? tag;
  int waiters = 0;
}

final _log = Logger('lyrics_loader');

/// One source's outcome: its lyrics (null = none) and whether it failed in a
/// way that may pass.
typedef _Source = ({Lyrics? lyrics, bool incomplete});

/// Reads the local lyrics of tracks for the whole app lifetime.
///
/// Tag and `.lrc` are read in parallel and independently: a failing source is
/// absent and the other still shows. The tag reads go through a [TagReadQueue]
/// (one at a time, newest first, stale ones dropped). Decode + parse run off
/// the UI isolate above [lyricsIsolateThreshold]. Finished reads are cached by
/// (track, audio path, revision, stat of the `.lrc` read), so an edited or
/// newly added `.lrc` is read again; a read with a transiently failed source
/// is returned but not cached.
///
/// Logs carry error kinds and track ids only, never paths or lyrics text.
class LyricsLoader {
  LyricsLoader(
    this._reader, {
    LyricsReadCache? cache,
    IsolateRunner runner = runInIsolate,
  }) : _cache = cache ?? LyricsReadCache(),
       _run = runner,
       _tags = TagReadQueue(_reader);

  final LocalLyricsReader _reader;
  final LyricsReadCache _cache;
  final IsolateRunner _run;
  final TagReadQueue _tags;
  final _inFlight = <LyricsCacheKey, _Flight>{};

  /// The newest cached read of [id]; synchronous, no I/O (menus).
  LocalLyricsRead? peek(TrackId id) => _cache.peek(id);

  /// Reads [request]. [cancel] withdraws it when the requester goes away:
  /// the tag read is dropped if it still waits and nobody else wants it, and
  /// the future then fails with [LyricsSuperseded].
  Future<LocalLyricsRead> load(
    LyricsRequest request, {
    LoadCancel? cancel,
  }) async {
    final (lrcStat, statFailed) = await _statLrc(request);
    final key = (
      request.trackId,
      request.audioPath,
      request.trackRevision,
      lrcStat,
    );
    final cached = _cache.get(key);
    if (cached != null) return cached;
    var flight = _inFlight[key];
    if (flight == null) {
      flight = _inFlight[key] = _Flight();
      flight.future = _read(request, key, lrcStat, statFailed, flight);
      final started = flight;
      // Block bodies: `remove` returns the flight, not a future to adopt.
      void forget() {
        _inFlight.remove(key);
      }

      started.future.then<void>(
        (_) => forget(),
        onError: (Object _) => forget(),
      );
    }
    final joined = flight;
    joined.waiters++;
    cancel?.onCancel(() {
      if (--joined.waiters > 0) return;
      // Nobody waits. Only a read dropped from the queue is forgotten (a
      // later request starts a fresh one); a running read stays joinable.
      final dropped = joined.tag?.cancel() ?? false;
      if (dropped && identical(_inFlight[key], joined)) _inFlight.remove(key);
    });
    return joined.future;
  }

  Future<LocalLyricsRead> _read(
    LyricsRequest request,
    LyricsCacheKey key,
    LrcStat? lrcStat,
    bool statFailed,
    _Flight flight,
  ) async {
    final results = await Future.wait([
      _tagSource(request, flight),
      lrcStat == null ? Future.value(_absent) : _lrcSource(request, lrcStat),
    ]);
    final read = LocalLyricsRead(
      tag: results[0].lyrics,
      lrc: results[1].lyrics,
      incomplete: statFailed || results[0].incomplete || results[1].incomplete,
    );
    if (!read.incomplete) _cache.put(key, read);
    return read;
  }

  static const _absent = (lyrics: null, incomplete: false);

  /// The `.lrc` to read: the scan's file, else the first of the probed
  /// spellings that is a regular file. A stat that fails transiently makes the
  /// read incomplete.
  Future<(LrcStat?, bool)> _statLrc(LyricsRequest request) async {
    final paths = request.lrcPath != null
        ? [request.lrcPath!]
        : lrcProbeCandidates(request.audioPath);
    var failed = false;
    for (final path in paths) {
      try {
        final stat = await _reader.statLrc(path);
        if (stat != null) return (stat, failed);
      } on LyricsReadFailure catch (f) {
        _log.info('track ${request.trackId.value}: .lrc stat ${f.kind}');
        failed = failed || f.transient;
      } on Object catch (e) {
        _log.warning(
          'track ${request.trackId.value}: .lrc stat failed: ${e.runtimeType}',
        );
        failed = true;
      }
    }
    return (null, failed);
  }

  Future<_Source> _tagSource(LyricsRequest request, _Flight flight) async {
    final EmbeddedLyrics? tag;
    try {
      final read = flight.tag = _tags.read(request.audioPath);
      tag = await read.result;
    } on LyricsSuperseded {
      rethrow;
    } on Object catch (e) {
      return _failed(request.trackId, 'tag', e);
    }
    return _parsed(request.trackId, 'tag', () => _tagLyrics(tag));
  }

  Future<Lyrics?> _tagLyrics(EmbeddedLyrics? tag) {
    if (tag == null) return Future.value();
    if (tag.synced.isNotEmpty) return Future.value(lyricsFromTag(tag));
    final text = tag.text;
    return text == null ? Future.value() : parseTagText(text, _run);
  }

  Future<_Source> _lrcSource(LyricsRequest request, LrcStat stat) async {
    final LrcFile? file;
    try {
      file = await _reader.readLrc(stat);
    } on Object catch (e) {
      return _failed(request.trackId, 'lrc', e);
    }
    if (file == null) return _absent;
    return _parsed(
      request.trackId,
      'lrc',
      () => parseLrcBytes(file!.bytes, _run),
    );
  }

  /// A parse that fails fails the same way every time (the content is
  /// unchanged under the same key), so it counts as "no lyrics" and is cached.
  Future<_Source> _parsed(
    TrackId id,
    String source,
    Future<Lyrics?> Function() parse,
  ) async {
    try {
      return (lyrics: await parse(), incomplete: false);
    } on Object catch (e) {
      _log.warning('track ${id.value}: $source parse failed: ${e.runtimeType}');
      return _absent;
    }
  }

  /// A source that failed: transient failures (and anything unknown) leave
  /// the read incomplete; permanent ones mean "nothing there".
  _Source _failed(TrackId id, String source, Object error) {
    if (error is LyricsReadFailure) {
      _log.info('track ${id.value}: $source read ${error.kind}');
      return (lyrics: null, incomplete: error.transient);
    }
    _log.warning(
      'track ${id.value}: $source read failed: ${error.runtimeType}',
    );
    return (lyrics: null, incomplete: true);
  }
}
