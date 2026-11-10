import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../domain/local_audio_catalog.dart';
import 'audio_tree_walk.dart';

/// Message sent to the walk isolate.
class WalkMessage {
  const WalkMessage(this.request, this.reply);

  final WalkRequest request;
  final SendPort reply;
}

/// Entry point of the walk isolate; swapped in tests. Must be top-level.
typedef WalkEntry = void Function(WalkMessage message);

/// Default [WalkEntry]: walks and replies with the listing.
void walkEntry(WalkMessage message) {
  // Hands the listing over without copying it; the reply arrives before exit.
  Isolate.exit(message.reply, walkAudioTree(message.request));
}

/// A root walk is killed after this long (network roots can hang).
const defaultWalkTimeout = Duration(seconds: 120);

/// Runs [walkAudioTree] on killable isolates, one at a time per root.
///
/// An isolate stuck in a system call may outlive its kill. Its root stays
/// "busy" until the isolate's exit port fires, and while busy the root is
/// reported unreachable without spawning another walk, so stuck isolates
/// cannot pile up.
class WalkIsolateRunner {
  WalkIsolateRunner({
    this.entry = walkEntry,
    this.timeout = defaultWalkTimeout,
  });

  static final _log = Logger('platform.files');

  final WalkEntry entry;
  final Duration timeout;
  final Set<String> _busy = {};

  int _spawned = 0;

  /// Walks spawned so far.
  @visibleForTesting
  int get spawned => _spawned;

  /// Whether an isolate for [root] has not exited yet.
  bool isBusy(String root) => _busy.contains(root);

  Future<AudioListing> run(WalkRequest request) async {
    final root = request.root;
    if (!_busy.add(root)) {
      _log.warning('Walk of $root still running from an earlier scan');
      return const AudioListing.unreachable(UnreachableReason.busy);
    }
    final reply = ReceivePort();
    final exit = ReceivePort();
    final errors = ReceivePort();
    final done = Completer<AudioListing>();

    reply.listen((message) {
      if (message is AudioListing && !done.isCompleted) done.complete(message);
    });
    errors.listen((error) {
      _log.warning('Walk of $root failed: $error');
      if (!done.isCompleted) done.complete(const AudioListing.unreachable());
    });
    exit.listen((_) {
      _busy.remove(root);
      exit.close();
      reply.close();
      errors.close();
      if (!done.isCompleted) done.complete(const AudioListing.unreachable());
    });

    final Isolate isolate;
    try {
      _spawned++;
      isolate = await Isolate.spawn(
        entry,
        WalkMessage(request, reply.sendPort),
        onExit: exit.sendPort,
        onError: errors.sendPort,
        errorsAreFatal: true,
      );
    } on Object catch (error, stack) {
      _log.warning('Could not start the walk of $root', error, stack);
      _busy.remove(root);
      exit.close();
      reply.close();
      errors.close();
      return const AudioListing.unreachable();
    }
    return done.future.timeout(
      timeout,
      onTimeout: () {
        _log.warning('Walk of $root timed out after $timeout; killing it');
        isolate.kill(priority: Isolate.immediate);
        return const AudioListing.unreachable(UnreachableReason.timedOut);
      },
    );
  }
}
