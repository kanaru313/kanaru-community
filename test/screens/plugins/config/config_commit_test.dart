import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/state/config_form_provider.dart';
import 'package:kanaru/src/screens/plugins/config/config_commit.dart';

class _Send {
  final sent = <Object?>[];
  final gates = <Completer<ConfigWrite>>[];

  Future<ConfigWrite> call(Object? value) {
    sent.add(value);
    final gate = Completer<ConfigWrite>();
    gates.add(gate);
    return gate.future;
  }
}

void main() {
  test('one save is in flight; the latest value waits and goes next', () async {
    final send = _Send();
    final commit = ConfigCommit(send.call);
    commit
      ..submit('a')
      ..submit('b')
      ..submit('c');
    expect(send.sent, ['a']);
    expect(commit.busy, isTrue);
    send.gates[0].complete(ConfigWrite.written);
    await pumpEventQueue();
    // 'b' was replaced by 'c' while waiting.
    expect(send.sent, ['a', 'c']);
    send.gates[1].complete(ConfigWrite.written);
    await commit.idle;
    expect(commit.busy, isFalse);
    expect(commit.refusal, isNull);
  });

  test(
    'a refusal is kept until the user edits or a save goes through',
    () async {
      final send = _Send();
      var changes = 0;
      final commit = ConfigCommit(send.call, onChanged: () => changes++);
      commit.submit('x');
      send.gates[0].complete(ConfigWrite.invalidValue);
      await commit.idle;
      expect(commit.refusal, ConfigWrite.invalidValue);
      expect(changes, 1);
      commit.dismiss();
      expect(commit.refusal, isNull);
      expect(changes, 2);
      commit.submit('y');
      send.gates[1].complete(ConfigWrite.tooLarge);
      await commit.idle;
      commit.submit('z');
      send.gates[2].complete(ConfigWrite.written);
      await commit.idle;
      expect(commit.refusal, isNull);
    },
  );

  test(
    'a refusal that a newer waiting value replaces is not reported',
    () async {
      final send = _Send();
      final commit = ConfigCommit(send.call);
      commit
        ..submit(1)
        ..submit(2);
      send.gates[0].complete(ConfigWrite.invalidValue);
      await pumpEventQueue();
      expect(commit.refusal, isNull);
      send.gates[1].complete(ConfigWrite.written);
      await commit.idle;
      expect(commit.refusal, isNull);
    },
  );

  test('a send that throws is a failed write, not a crash', () async {
    final commit = ConfigCommit((_) async => throw StateError('boom'));
    commit.submit('x');
    await commit.idle;
    expect(commit.refusal, ConfigWrite.failed);
  });

  test('after detach saves still finish but nobody is told', () async {
    final send = _Send();
    var changes = 0;
    final commit = ConfigCommit(send.call, onChanged: () => changes++);
    commit
      ..submit('a')
      ..submit('last')
      ..detach();
    send.gates[0].complete(ConfigWrite.written);
    await pumpEventQueue();
    expect(send.sent, ['a', 'last']);
    send.gates[1].complete(ConfigWrite.written);
    await commit.idle;
    expect(changes, 0);
  });

  test('idle completes at once when nothing is going on', () async {
    final commit = ConfigCommit((_) async => ConfigWrite.written);
    await commit.idle;
    expect(commit.busy, isFalse);
  });
}
