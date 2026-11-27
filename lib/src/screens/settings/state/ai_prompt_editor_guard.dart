import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the route ask the open editor before the router leaves it (a sidebar
/// or top bar jump, Back of the window). The editor page attaches while it is
/// open; with no page attached leaving is always allowed.
class PromptEditorGuard {
  Future<bool> Function()? _confirm;

  /// The page registers how to ask the user; true = leaving is fine.
  void attach(Future<bool> Function() confirm) => _confirm = confirm;

  /// Only the page that attached [confirm] detaches it.
  void detach(Future<bool> Function() confirm) {
    if (_confirm == confirm) _confirm = null;
  }

  /// True when the router may leave the editor.
  FutureOr<bool> mayLeave() => _confirm?.call() ?? true;
}

final promptEditorGuardProvider = Provider<PromptEditorGuard>(
  (ref) => PromptEditorGuard(),
);
