import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../plugins/state/plugin_actions_provider.dart';

final _log = Logger('plugin_restore');

/// Starts the reinstall of plugins whose package folder is missing (the first
/// read of [pluginRestoreProvider] runs it) and logs a failure. It never
/// blocks the screen that calls it: nothing waits on the result.
void watchPluginRestore(WidgetRef ref) {
  ref.listen(pluginRestoreProvider, (_, next) {
    if (next.hasError) {
      _log.warning('Restoring plugins failed: ${next.error.runtimeType}');
    }
  });
}
