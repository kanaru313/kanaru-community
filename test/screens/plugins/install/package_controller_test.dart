import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/screens/plugins/install/package_controller.dart';
import 'package:kanaru/src/screens/plugins/install/package_exit.dart';

import '../support/install_fixtures.dart';

PackageController _controller(
  FakeInstallOps ops, {
  void Function(PackageInstalled)? late,
}) => PackageController(
  ops: ops,
  start: () => ops.prepareInstall('id-demo'),
  subject: const PackageSubject('Demo'),
  onInstalledAfterClose: late,
);

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'a failing streaming check ends in the failed phase, token dropped',
    () async {
      final ops = FakeInstallOps()
        ..onStreamingBlocked = (_) async => throw StateError('boom');
      final c = _controller(ops);
      addTearDown(c.dispose);
      await c.prepare();
      expect(c.phase, PackagePhase.failed);
      expect(c.writeFailure, InstallFailure.unexpected);
      expect(c.held, isNull);
      expect(ops.discarded, contains('token-1'));
    },
  );

  test('an install that throws ends in the failed phase', () async {
    final ops = FakeInstallOps()
      ..onInstall = (_) async => throw StateError('boom');
    final c = _controller(ops);
    addTearDown(c.dispose);
    await c.prepare();
    await c.confirm();
    expect(c.phase, PackagePhase.failed);
    expect(c.writeFailure, InstallFailure.unexpected);
    expect(c.exit, isNull);
  });

  test('a plugin written after the screen closed is still announced', () async {
    final gate = Completer<InstallResult>();
    final ops = FakeInstallOps()..onInstall = (_) => gate.future;
    final seen = <PackageInstalled>[];
    final c = _controller(ops, late: seen.add);
    await c.prepare();
    final running = c.confirm();
    await _settle();
    c.dispose();
    gate.complete(const Installed('id-demo', InstallOutcome.installed));
    await running;
    expect(seen, hasLength(1));
    expect(seen.single.installId, 'id-demo');
    expect(c.exit, isNull);
  });

  test('a throwing install after the screen closed reports nothing', () async {
    final gate = Completer<InstallResult>();
    final ops = FakeInstallOps()..onInstall = (_) => gate.future;
    final seen = <PackageInstalled>[];
    final c = _controller(ops, late: seen.add);
    await c.prepare();
    final running = c.confirm();
    await _settle();
    c.dispose();
    gate.completeError(StateError('boom'));
    await running;
    expect(seen, isEmpty);
  });

  test('an open screen gets the exit, not the late callback', () async {
    final ops = FakeInstallOps();
    final seen = <PackageInstalled>[];
    final c = _controller(ops, late: seen.add);
    addTearDown(c.dispose);
    await c.prepare();
    await c.confirm();
    expect(c.exit, isA<PackageInstalled>());
    expect(seen, isEmpty);
  });
}
