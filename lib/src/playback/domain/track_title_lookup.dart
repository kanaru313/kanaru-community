import '../../media/domain/track_id.dart';

/// Titles for notices.
abstract interface class TrackTitleLookup {
  /// The title of [id]; empty when unknown.
  Future<String> titleOf(TrackId id);
}
