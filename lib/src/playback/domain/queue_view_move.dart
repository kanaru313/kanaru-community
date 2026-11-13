import 'playback_views.dart';

/// [v] with the entry [entryId] moved to play-order index [toIndex] (index in
/// the list after the move; clamped), without touching the sort keys.
///
/// Mirrors the position rule of `move` in `queue_logic.dart`, so the UI can
/// show a reorder before the controller has applied it. [v] is returned as is
/// when the entry is unknown or would not change place.
QueueView moveInView(QueueView v, int entryId, int toIndex) {
  final from = v.items.indexWhere((i) => i.entryId == entryId);
  if (from < 0 || v.items.length < 2) return v;
  final to = toIndex.clamp(0, v.items.length - 1);
  if (to == from) return v;
  final curId = v.current == null ? null : v.items[v.current!].entryId;
  final moved = v.items[from];
  final items = [...v.items]
    ..removeAt(from)
    ..insert(to, moved);
  return QueueView(
    items: items,
    current: curId == null ? null : items.indexWhere((i) => i.entryId == curId),
    shuffled: v.shuffled,
    repeat: v.repeat,
    repeatTimes: v.repeatTimes,
    stopped: v.stopped,
  );
}
