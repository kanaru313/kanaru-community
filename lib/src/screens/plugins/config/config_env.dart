import 'package:flutter/widgets.dart';

import '../../../plugins/state/config_form_provider.dart';
import 'config_commit.dart';

/// What every editor of the form needs: which plugin, how to write, and
/// whether the form is locked (dimmed, not focusable).
class ConfigEnv {
  const ConfigEnv({
    required this.installId,
    required this.ops,
    this.locked = false,
  });

  final String installId;
  final ConfigOps ops;
  final bool locked;
}

/// The save of one field for the state of its editor: one [commit] queue
/// that rebuilds the editor when a save ends, and that outlives it.
mixin ConfigCommitHost<T extends StatefulWidget> on State<T> {
  ConfigEnv get env;
  String get fieldKey;

  late final ConfigCommit commit = ConfigCommit(
    (value) => env.ops.setValue(env.installId, fieldKey, value),
    onChanged: () {
      if (mounted) setState(() {});
    },
  );

  /// Call from `dispose`, after the last edit was submitted: the saves still
  /// finish, the editor is no longer told.
  void detachCommit() => commit.detach();
}
