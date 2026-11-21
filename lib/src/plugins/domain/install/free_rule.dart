/// The Free one-music-source rule: without Pro only one streaming plugin may
/// work. One function decides who holds that slot, for the install gate, the
/// alerts and the store list alike.
///
/// The holder is the oldest live streaming plugin whose package folder is
/// there ([liveStreamingIds] are oldest first, [missingIds] the ones whose
/// folder is gone); when none has a folder, the oldest live streaming plugin.
/// A plugin restored later never displaces a working one.
String? streamingSlotHolder(
  Iterable<String> liveStreamingIds,
  Set<String> missingIds,
) {
  String? oldest;
  for (final id in liveStreamingIds) {
    oldest ??= id;
    if (!missingIds.contains(id)) return id;
  }
  return oldest;
}

/// The streaming plugins in [liveStreamingIds] that may not work now: all but
/// the slot holder, none with Pro.
Set<String> lockedStreamingIds({
  required bool unlocked,
  required Iterable<String> liveStreamingIds,
  Set<String> missingIds = const {},
}) {
  if (unlocked) return const {};
  final holder = streamingSlotHolder(liveStreamingIds, missingIds);
  return {
    for (final id in liveStreamingIds)
      if (id != holder) id,
  };
}

/// Whether the streaming plugin [installId] may be written (installed,
/// updated, repaired, restored): always with Pro, else only when it holds the
/// slot or nobody does. The holder's own update or repair is never blocked.
bool streamingInstallAllowed({
  required bool unlocked,
  required String installId,
  required Iterable<String> liveStreamingIds,
  Set<String> missingIds = const {},
}) {
  if (unlocked) return true;
  final holder = streamingSlotHolder(liveStreamingIds, missingIds);
  return holder == null || holder == installId;
}
