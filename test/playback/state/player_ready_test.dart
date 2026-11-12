import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/state/player_controller.dart';
import 'package:kanaru/src/playback/state/player_ready.dart';

/// Only [settled] is used by the notifier.
class _Player implements PlayerController {
  _Player(this.done);
  final Future<void> done;

  @override
  Future<void> settled() => done;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer c;
  setUp(() {
    c = ProviderContainer();
    addTearDown(c.dispose);
  });

  test('starts not created and not ready, without creating a player', () {
    expect(c.read(playerCreatedProvider), isFalse);
    expect(c.read(playerReadyProvider), isFalse);
  });

  test('created at once, ready when the restore is over', () async {
    final done = Completer<void>();
    final attached = c
        .read(playerPhaseProvider.notifier)
        .attach(_Player(done.future));
    expect(c.read(playerPhaseProvider), PlayerPhase.restoring);
    expect(c.read(playerCreatedProvider), isTrue);
    expect(c.read(playerReadyProvider), isFalse);
    done.complete();
    await attached;
    expect(c.read(playerReadyProvider), isTrue);
  });

  test('disposed while waiting: no write after dispose, no error', () async {
    final done = Completer<void>();
    final attached = c
        .read(playerPhaseProvider.notifier)
        .attach(_Player(done.future));
    c.dispose();
    done.complete();
    // A state write on a disposed notifier would throw out of `attach`.
    await expectLater(attached, completes);
  });

  test('a second attach is ignored', () async {
    final first = Completer<void>();
    final notifier = c.read(playerPhaseProvider.notifier);
    final attached = notifier.attach(_Player(first.future));
    await notifier.attach(_Player(Future<void>.value()));
    expect(c.read(playerReadyProvider), isFalse);
    first.complete();
    await attached;
    expect(c.read(playerReadyProvider), isTrue);
  });
}
