import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auto_mode_confirm.dart';

/// The shape of [confirmAutoMode], so a test can hand the picker its own.
typedef AutoModeConfirm = Future<bool> Function(
  BuildContext context,
  WidgetRef ref, {
  required AutoModeScope scope,
});

/// The confirm the permission picker uses; tests override it.
final chatAutoModeConfirmProvider = Provider<AutoModeConfirm>(
  (ref) => confirmAutoMode,
);
