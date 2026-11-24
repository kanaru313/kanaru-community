import 'dart:async';

import 'package:logging/logging.dart';

import 'translation_services.dart';

final _log = Logger('translation_config');

/// Counts the saves of each plugin's settings while some job of that plugin
/// exists. The count is the "epoch" a job started in: a job that fails in a
/// later epoch used settings that were replaced meanwhile.
class PluginConfigEpochs {
  PluginConfigEpochs(this._services, this._onSaved);

  final TranslationServices _services;

  /// Called with the plugin's id after each save (not for the baseline).
  final void Function(String installId) _onSaved;

  final _epochs = <String, int>{};
  final _subs = <String, StreamSubscription<Object?>>{};

  /// The saves seen so far for [installId].
  int of(String installId) => _epochs[installId] ?? 0;

  /// Counts a save of [installId] and tells the owner.
  void _saved(String installId) {
    _epochs[installId] = of(installId) + 1;
    _onSaved(installId);
  }

  /// Watches [installId] while [hasJobs], stops when it has none. The first
  /// emission is the settings as they are now, not a save.
  void sync(String installId, {required bool hasJobs}) {
    final sub = _subs[installId];
    if (hasJobs && sub == null) {
      var baseline = true;
      _subs[installId] = _services.configChanges(installId).listen(
        (_) {
          if (baseline) {
            baseline = false;
            return;
          }
          _saved(installId);
        },
        onError: (Object e) =>
            _log.warning('Plugin config watch failed: ${e.runtimeType}'),
      );
    } else if (!hasJobs && sub != null) {
      _subs.remove(installId);
      unawaited(sub.cancel());
    }
  }

  void dispose() {
    for (final sub in _subs.values) {
      unawaited(sub.cancel());
    }
    _subs.clear();
  }
}
