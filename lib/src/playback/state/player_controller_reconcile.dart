part of 'player_controller.dart';

/// Making the engine match the desired state.
extension _Reconcile on PlayerController {
  Future<void> _reconcileIfDirty() async {
    if (!_dirty || _disposed) return;
    _dirty = false;
    try {
      await _reconcile();
    } on Object catch (e, st) {
      _log.warning('reconcile failed: $e', e, st);
    } finally {
      _publish();
    }
  }

  /// Empties the engine; the entry stays current.
  Future<void> _halt() async {
    final engine = _engine;
    _startAt = _position;
    _loaded = null;
    _handedNext = null;
    _loadedOk = false;
    if (engine != null) await engine.stop();
    _enginePlaying = false;
    try {
      await _focus.deactivate();
    } on Object catch (e) {
      _log.fine('deactivate failed: $e');
    }
  }

  Future<bool> _activateFocus() async {
    try {
      return await _focus.activate().timeout(_focusTimeout);
    } on Object {
      return false;
    }
  }

  AudioEngine _ensureEngine() {
    final existing = _engine;
    if (existing != null) return existing;
    final engine = _engineFactory();
    _engine = engine;
    // Subscribe in the zone the controller was made in, so handlers may run
    // chain tasks.
    _homeZone.run(() {
      _subs.add(
        engine.events.listen((e) {
          _chain
              .run(() => _onEngineEvent(e))
              .then<void>(
                (_) {},
                onError: (Object err) {
                  _log.warning('engine event failed: $err');
                },
              );
        }),
      );
      _subs.add(
        engine.position.listen((p) {
          // Ticks of a file that is about to be replaced do not count.
          if (_loaded == null || _atEnd || !_loadedOk || _forceReload) return;
          _position = p;
          _pos.add(
            PlaybackPosition(
              entryId: _queue.currentItem?.entryId,
              position: p,
              duration: _loadedOk ? _duration : null,
            ),
          );
        }),
      );
    });
    unawaited(engine.setVolume(_volume.toDouble()));
    return engine;
  }

  Future<void> _reconcile() async {
    if (_queue.current == null || _queue.items.isEmpty) {
      if (_loaded != null || _engine != null) await _halt();
      return;
    }
    if (_intent == PlayIntent.stopped) {
      if (_loaded != null) await _halt();
      return;
    }

    // Find the entry to play: skip what cannot play, once per run. Entries
    // are resolved in windows of 50, one query each.
    final cache = <int, Playable>{};
    Playable? playable;
    TrackId? firstSkipped;
    UnplayableReason? firstReason;
    var skipped = 0;
    while (true) {
      final item = _queue.currentItem!;
      final resolved = await _playableAt(_queue.current!, cache);
      final bad = _bad.contains(item.entryId);
      if (resolved is LocalFile && !bad) {
        playable = resolved;
        break;
      }
      if (restoring) {
        // A restored entry that cannot play stays current: no skip, no write.
        return;
      }
      skipped++;
      if (!bad) {
        firstSkipped ??= item.trackId;
        firstReason ??= (resolved as Unplayable).reason;
      }
      final i = skipped >= _queue.length
          ? null
          : nextIndex(_queue, auto: false);
      if (i == null || i == _queue.current) {
        _intent = PlayIntent.stopped;
        _notice(const QueueEnd());
        break;
      }
      _queue = _queue.withCurrent(i, _queue.playNextRunIds);
      _rewind();
      _forceReload = true;
    }
    if (firstSkipped != null) {
      _notice(
        TrackSkipped(
          await _titles.titleOf(firstSkipped),
          firstReason!,
          skipped,
        ),
      );
    }
    if (playable is! LocalFile) {
      if (_loaded != null) await _halt();
      return;
    }

    final current = _queue.currentItem!;
    final nextEntry = await _nextCandidate(cache);
    final engine = _ensureEngine();

    if (_forceReload ||
        _loaded == null ||
        _loaded!.entryId != current.entryId) {
      _forceReload = false;
      var play = _intent == PlayIntent.playing;
      if (play && !await _activateFocus()) {
        _intent = PlayIntent.paused;
        _notice(const FocusDenied());
        play = false;
      }
      _generation++;
      _handoff++;
      final token = EngineToken(
        entryId: current.entryId,
        generation: _generation,
        handoff: _handoff,
      );
      EngineMedia? nextMedia;
      if (nextEntry != null) {
        _handoff++;
        nextMedia = EngineMedia(
          EngineToken(
            entryId: nextEntry.entryId,
            generation: _generation,
            handoff: _handoff,
          ),
          nextEntry.path,
        );
      }
      _loaded = token;
      _handedNext = nextMedia?.token;
      _handedSkip = nextEntry?.skip;
      _loadedOk = false;
      _position = _startAt;
      _enginePlaying = play;
      await engine.load(
        EngineMedia(token, playable.path),
        next: nextMedia,
        play: play,
        start: _startAt,
      );
      return;
    }

    // Same entry: hand a different next, or flip play/pause.
    if (nextEntry?.entryId != _handedNext?.entryId) {
      _handoff++;
      final media = nextEntry == null
          ? null
          : EngineMedia(
              EngineToken(
                entryId: nextEntry.entryId,
                generation: _generation,
                handoff: _handoff,
              ),
              nextEntry.path,
            );
      _handedNext = media?.token;
      _handedSkip = nextEntry?.skip;
      await engine.setNext(media);
    }
    final wantPlay = _intent == PlayIntent.playing;
    if (wantPlay && !_enginePlaying) {
      if (await _activateFocus()) {
        _enginePlaying = true;
        await engine.play();
      } else {
        _intent = PlayIntent.paused;
        _notice(const FocusDenied());
      }
    } else if (!wantPlay && _enginePlaying) {
      _enginePlaying = false;
      await engine.pause();
    }
  }

  /// [Playable] of the entry at [index], from [cache] or from one query for
  /// the next 50 entries in play order.
  Future<Playable> _playableAt(int index, Map<int, Playable> cache) async {
    final item = _queue.items[index];
    final hit = cache[item.entryId];
    if (hit != null) return hit;
    final window = _queue.items.sublist(index, min(index + 50, _queue.length));
    final resolved = await _resolver.resolve([
      for (final i in window) i.trackId,
    ]);
    for (final i in window) {
      cache[i.entryId] =
          resolved[i.trackId] ??
          const Unplayable(UnplayableReason.unknownTrack);
    }
    return cache[item.entryId]!;
  }

  /// The entry to hand over as "next": the one after the current (the
  /// current itself under repeat one), or the first playable one after it
  /// (looking at most 50 ahead). Entries passed over are reported in `skip`.
  Future<_NextPick?> _nextCandidate(Map<int, Playable> cache) async {
    var i = nextIndex(_queue, auto: true);
    if (i == null) return null;
    final start = _queue.current!;
    var skipped = 0;
    TrackId? first;
    UnplayableReason? reason;
    for (var step = 0; step < 50; step++) {
      final item = _queue.items[i!];
      final bad = _bad.contains(item.entryId);
      final p = bad ? null : await _playableAt(i, cache);
      if (p is LocalFile) {
        return _NextPick(
          item.entryId,
          p.path,
          first == null
              ? null
              : (track: first, reason: reason!, count: skipped),
        );
      }
      if (_queue.repeat == RepeatMode.one) return null;
      skipped++;
      if (!bad && first == null) {
        first = item.trackId;
        reason = (p as Unplayable).reason;
      }
      final n = i + 1 < _queue.length
          ? i + 1
          : (_queue.repeat == RepeatMode.all ? 0 : null);
      if (n == null || n == start) return null;
      i = n;
    }
    return null;
  }
}

/// The entry handed over as next, and what was passed over to reach it.
class _NextPick {
  const _NextPick(this.entryId, this.path, this.skip);
  final int entryId;
  final String path;
  final ({TrackId track, UnplayableReason reason, int count})? skip;
}
