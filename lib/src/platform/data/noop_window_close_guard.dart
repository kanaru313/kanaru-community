import '../domain/window_close.dart';

/// Android and tests: does nothing. On Android the lifecycle listener's exit
/// request covers exit; tests pin it so no window plugin is touched.
class NoopWindowCloseGuard implements WindowCloseGuard {
  const NoopWindowCloseGuard();

  @override
  Future<void> install(Future<void> Function() beforeClose) async {}
}
