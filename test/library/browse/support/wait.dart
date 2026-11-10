/// Polls [condition] every few milliseconds until it holds. For tests that
/// wait on real database I/O and real timers: a generous [timeout] keeps a
/// loaded machine from failing them, and a fast condition returns at once.
Future<void> until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String what = 'condition',
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw StateError('$what not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// Waits until the provider under test has finished a load after the write:
/// [loads] counts its finished queries (see `QueryCounter`) and [after] is
/// its value taken **before** the write. The emission, if any, is delivered
/// one event later.
Future<void> afterLoad(int Function() loads, {required int after}) async {
  await until(() => loads() > after, what: 'load of the provider under test');
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

/// For "nothing loads" assertions, where there is no load to count: waits
/// until [revisions], a sibling provider that reloads on the same writes, has
/// grown past [after] (its length **before** the write), then a short beat.
/// It proves time has passed, not that the other provider ran.
Future<void> afterSiblingReload(
  List<int> revisions, {
  required int after,
}) async {
  await until(() => revisions.length > after, what: 'sibling reload');
  await Future<void>.delayed(const Duration(milliseconds: 60));
}
