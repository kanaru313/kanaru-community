/// Names one load of one queue entry. [generation] increases on every
/// `load`; [handoff] increases on every `load` and every `setNext`, so two
/// loops of the same entry (repeat one) carry different tokens.
class EngineToken {
  const EngineToken({
    required this.entryId,
    required this.generation,
    required this.handoff,
  });

  final int entryId;
  final int generation;
  final int handoff;

  @override
  bool operator ==(Object other) =>
      other is EngineToken &&
      other.entryId == entryId &&
      other.generation == generation &&
      other.handoff == handoff;

  @override
  int get hashCode => Object.hash(entryId, generation, handoff);

  @override
  String toString() =>
      'EngineToken(entry $entryId, gen $generation, handoff $handoff)';
}

/// A file to play and the token its events carry.
class EngineMedia {
  const EngineMedia(this.token, this.path);

  final EngineToken token;
  final String path;
}

sealed class EngineEvent {
  const EngineEvent();
}

/// The engine moved on to the entry that was handed over as "next".
class EngineAdvanced extends EngineEvent {
  const EngineAdvanced(this.token);
  final EngineToken token;
}

/// The entry reported its duration (it opened).
class EngineLoaded extends EngineEvent {
  const EngineLoaded(this.token, this.duration);
  final EngineToken token;
  final Duration duration;
}

/// The entry could not be played.
class EngineFailed extends EngineEvent {
  const EngineFailed(this.token, this.message);
  final EngineToken token;
  final String message;
}

/// The last entry reached its end and nothing was handed after it.
class EngineEnded extends EngineEvent {
  const EngineEnded(this.token);
  final EngineToken token;
}

/// A seek finished.
class EngineSeeked extends EngineEvent {
  const EngineSeeked(this.position);
  final Duration position;
}

/// The player behind the queue. It holds at most the current and the next
/// entry; the controller owns the queue and decides what plays. Commands run
/// one after another; a failing command does not block the next ones, and
/// every command is a no-op after [dispose].
abstract interface class AudioEngine {
  /// Replaces what is loaded: [current] (from [start]) and optionally [next]
  /// for a gapless advance. Starts playing only when [play] is true.
  Future<void> load(
    EngineMedia current, {
    EngineMedia? next,
    required bool play,
    Duration start = Duration.zero,
  });

  /// Replaces the entry after the current one (null = none).
  Future<void> setNext(EngineMedia? next);

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);

  /// [volume0to100] in 0..100.
  Future<void> setVolume(double volume0to100);

  Stream<EngineEvent> get events;
  Stream<Duration> get position;

  /// Informational: the controller's intent decides play and pause.
  Stream<bool> get playing;

  Future<void> dispose();
}
