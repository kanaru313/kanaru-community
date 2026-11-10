/// Gives other work on the UI isolate a turn between slices of scan work.
///
/// The database runs on its own isolate, but building rows and handling
/// results still happens here, so a long run of batches yields once a time
/// budget has passed.
class ScanYield {
  ScanYield({this.budget = const Duration(milliseconds: 6)}) {
    _clock.start();
  }

  final Duration budget;
  final Stopwatch _clock = Stopwatch();

  /// Yields when [budget] has passed since the last yield.
  Future<void> tick() async {
    if (_clock.elapsed < budget) return;
    await now();
  }

  /// Yields unconditionally and restarts the budget.
  Future<void> now() async {
    await Future<void>.delayed(Duration.zero);
    _clock
      ..reset()
      ..start();
  }
}
