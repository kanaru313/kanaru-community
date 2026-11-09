import 'package:drift/drift.dart';

import 'tables.dart';

final _aliasPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

/// SQL condition for library views: rows of `tracks` (aliased [alias]) that
/// are in the library. Only `present` rows are visible; `missing`, `hidden`
/// and `remote` rows are not. Lifecycle helpers already set `hidden` for
/// removed sources and disabled mounts, so no source join is needed. Served
/// by the partial index `tracks_present_title`.
///
/// Throws [ArgumentError] when [alias] is not a plain SQL identifier.
String visibleTrackWhere(String alias) {
  if (!_aliasPattern.hasMatch(alias)) {
    throw ArgumentError.value(alias, 'alias', 'must be a plain SQL identifier');
  }
  return "$alias.status = '${TrackStatus.present}'";
}

/// Typed form of [visibleTrackWhere]: use in `select(tracks)..where(...)`.
Expression<bool> isVisibleTrack($TracksTable tracks) =>
    tracks.status.equals(TrackStatus.present);
