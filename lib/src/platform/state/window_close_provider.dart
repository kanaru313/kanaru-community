import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/linux_window_close_guard.dart';
import '../data/noop_window_close_guard.dart';
import '../domain/window_close.dart';

/// Window close takeover: the Linux guard on Linux, a no-op elsewhere. The
/// widget test harness pins it to the no-op.
final windowCloseGuardProvider = Provider<WindowCloseGuard>((ref) {
  if (Platform.isLinux) return LinuxWindowCloseGuard();
  return const NoopWindowCloseGuard();
});
