import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where "Tự động" is being switched on.
enum AutoModeScope {
  /// The open conversation only.
  conversation,

  /// The permission every new conversation starts with.
  defaultForNew,
}

/// Asks the user to confirm switching to the automatic permission. True when
/// the choice may go ahead.
///
/// Stand-in until the AI settings work lands its shared dialog with the same
/// names and signature (`auto_mode_confirm.dart`); the rebase replaces this
/// file with it. Until then it confirms at once.
Future<bool> confirmAutoMode(
  BuildContext context,
  WidgetRef ref, {
  required AutoModeScope scope,
}) => Future.value(true);

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
