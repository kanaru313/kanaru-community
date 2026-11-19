import 'queue_state.dart';

/// Decides, for the player, whether playback must rest after the current
/// entry instead of going on. The player asks synchronously at the moment it
/// picks the entry to hand to the engine, so the answer always matches the
/// queue, repeat and shuffle as they are at that moment.
abstract interface class SleepStopPolicy {
  /// Whether the entry that is current in [queue] must be the last one before
  /// playback rests. [repeatTimes] is the extra plays of it still to come
  /// under a counted repeat. Called often: keep it cheap and free of effects.
  bool stopsAfterCurrent(QueueState queue, int repeatTimes);

  /// An entry ended by itself and did not stop playback (once per natural
  /// end), before the player decides what to hand over next.
  void trackEnded();
}

/// An entry the engine finished by itself (not a skip, a jump or a failure).
class TrackEnd {
  const TrackEnd({
    required this.entryId,
    required this.sleepStop,
    required this.queueEnded,
    this.policy,
  });

  /// The entry that ended.
  final int entryId;

  /// The stop policy stopped playback after it.
  final bool sleepStop;

  /// Nothing followed it: the queue ran out.
  final bool queueEnded;

  /// The policy that stopped playback (the player consumed it), set only when
  /// [sleepStop]. Lets the owner tell a stop of its current policy from the
  /// late stop of one it already replaced. Not part of equality.
  final SleepStopPolicy? policy;

  @override
  bool operator ==(Object other) =>
      other is TrackEnd &&
      other.entryId == entryId &&
      other.sleepStop == sleepStop &&
      other.queueEnded == queueEnded;

  @override
  int get hashCode => Object.hash(entryId, sleepStop, queueEnded);

  @override
  String toString() =>
      'TrackEnd($entryId, sleepStop: $sleepStop, queueEnded: $queueEnded)';
}
