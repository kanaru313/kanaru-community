import 'dart:async';

import 'playlist_overlay_edits.dart';

/// A write did not happen. [cancelled]: it was queued behind a write that
/// failed and never ran; [cause] is then the failure of that write. A page
/// shows one message per burst: the call with `cancelled == false`.
class PlaylistWriteFailure implements Exception {
  const PlaylistWriteFailure(this.cause, {this.cancelled = false});

  final Object cause;
  final bool cancelled;

  @override
  String toString() => 'PlaylistWriteFailure(cancelled: $cancelled, $cause)';
}

/// Why a write failed, with where.
typedef WriteError = ({Object error, StackTrace stack});

/// One queued write. [edit] is its optimistic effect on the shown entries.
abstract class WriteJob {
  WriteJob(this.edit);

  final DetailEdit? edit;

  /// Runs the write; null when it succeeded, else why not.
  Future<WriteError?> execute();

  void fail(PlaylistWriteFailure failure);
}

/// A write whose future carries the store's result. [failureOf] says whether
/// a result that arrived without a throw still counts as a failure.
class TypedWriteJob<R> extends WriteJob {
  TypedWriteJob(super.edit, this._run, this._failureOf);

  final Future<R> Function() _run;
  final Object? Function(R) _failureOf;
  final _done = Completer<R>();

  Future<R> get future => _done.future;

  @override
  Future<WriteError?> execute() async {
    try {
      final result = await _run();
      final failure = _failureOf(result);
      if (failure != null) return (error: failure, stack: StackTrace.current);
      _done.complete(result);
      return null;
    } on Object catch (error, stack) {
      return (error: error, stack: stack);
    }
  }

  @override
  void fail(PlaylistWriteFailure failure) => _done.completeError(failure);
}
