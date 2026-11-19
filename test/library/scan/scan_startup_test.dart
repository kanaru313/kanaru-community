import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/covers/cover_leftovers_sweep.dart';
import 'package:kanaru/src/library/state/scan/scan_capabilities.dart';
import 'package:kanaru/src/library/state/scan/scan_startup.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';

class _Scanner implements LibraryScanCommands, ScanStartupWork {
  int startups = 0;

  @override
  void ensureStartupWork() => startups++;

  @override
  Future<void> rescan({bool full = false}) async {}
}

class _PlainScanner implements LibraryScanCommands {
  @override
  Future<void> rescan({bool full = false}) async {}
}

void main() {
  test('the startup hook sweeps cover leftovers once and still starts the '
      'scanner work', () {
    var sweeps = 0;
    final scanner = _Scanner();
    final container = ProviderContainer(
      overrides: [
        coverLeftoversSweepProvider.overrideWithValue(() async => sweeps++),
        libraryScanCommandsProvider.overrideWithValue(scanner),
      ],
    );
    addTearDown(container.dispose);

    container.read(scanStartupWorkProvider)();

    expect(sweeps, 1);
    expect(scanner.startups, 1);
  });

  test('a scanner without startup work still gets the cover sweep', () {
    var sweeps = 0;
    final container = ProviderContainer(
      overrides: [
        coverLeftoversSweepProvider.overrideWithValue(() async => sweeps++),
        libraryScanCommandsProvider.overrideWithValue(_PlainScanner()),
      ],
    );
    addTearDown(container.dispose);

    container.read(scanStartupWorkProvider)();

    expect(sweeps, 1);
  });
}
