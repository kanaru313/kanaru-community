import 'package:logging/logging.dart';

import '../domain/audio_engine.dart';

final _log = Logger('LoadFailureGuard');

/// Runs an engine's `load` [body]. When it throws, the controller would wait
/// for ever (it has already marked the file as loading and gets neither
/// `EngineLoaded` nor `EngineFailed`), so the failure is reported as
/// [EngineFailed] for [current], and [onFailed] lets the engine drop what it
/// half set up. The handed-over next entry is not reported: it was never
/// tried, and the controller loads it itself after skipping [current]. The
/// error is logged, never rethrown: the controller's failure path (notice,
/// skip, failure cap) takes over.
Future<void> guardLoad({
  required EngineMedia current,
  required void Function(EngineEvent event) emit,
  required void Function() onFailed,
  required Future<void> Function() body,
}) async {
  try {
    await body();
  } on Object catch (e, st) {
    _log.warning('load failed: $e', e, st);
    onFailed();
    emit(EngineFailed(current.token, 'could not load the file'));
  }
}
