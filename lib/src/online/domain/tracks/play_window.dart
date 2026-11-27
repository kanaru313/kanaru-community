/// At most [max] of [items] around the one at [tapped], and where [tapped]
/// ends up inside them. Throws [RangeError] when [tapped] is not an index of
/// [items].
({List<T> items, int index}) playWindow<T>(
  List<T> items,
  int tapped, {
  int max = 200,
}) {
  RangeError.checkValidIndex(tapped, items, 'tapped');
  if (max < 1) throw RangeError.range(max, 1, null, 'max');
  final latestStart = items.length > max ? items.length - max : 0;
  final start = (tapped - max ~/ 2).clamp(0, latestStart);
  final end = start + max < items.length ? start + max : items.length;
  return (items: items.sublist(start, end), index: tapped - start);
}
