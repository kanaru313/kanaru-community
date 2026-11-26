import 'track_hit.dart';

/// Resolves raw track ids to what the user can see. Every tool, chip and
/// variable that takes a track id goes through this first.
abstract interface class TrackLookup {
  /// Splits [ids] into the visible tracks and the absent ids. Absent means
  /// missing, hidden, remote, hidden as a duplicate, or not in the database.
  ///
  /// `visible` keeps the order of [ids] and holds each track once (a repeated
  /// id is reported once, at its first position). `absent` keeps input order
  /// and each id once.
  Future<({List<TrackHit> visible, List<int> absent})> visibleOf(List<int> ids);
}
