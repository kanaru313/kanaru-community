import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/document_picker_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_services_provider.dart';

import '../../database/support/test_db.dart';
import '../data/services_test_support.dart';

class TestPaths implements AppPaths {
  TestPaths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

/// A container over an in-memory database; [unlocked] is the Pro state.
class StateHarness {
  StateHarness({bool unlocked = false, List<Override> more = const []}) {
    db = openTestDb();
    dir = tempDir();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(TestPaths(dir)),
        documentPickerProvider.overrideWithValue(
          FakePicker((_, _) async => throw StateError('unused')),
        ),
        scriptCheckerProvider.overrideWithValue(FakeChecker()),
        pluginFetcherProvider.overrideWithValue(
          FakeFetcher((_) async => throw StateError('offline')),
        ),
        pluginStreamingUnlockedProvider.overrideWithValue(unlocked),
        ...more,
      ],
    );
  }

  late final AppDatabase db;
  late final Directory dir;
  late final ProviderContainer container;

  /// Reads [provider] after the streams behind it delivered (a few turns of
  /// the event loop).
  Future<T> settled<T>(ProviderListenable<T> provider) async {
    final sub = container.listen(provider, (_, _) {});
    addListener(sub);
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return sub.read();
  }

  final _subs = <ProviderSubscription<Object?>>[];
  void addListener(ProviderSubscription<Object?> sub) => _subs.add(sub);

  Future<void> dispose() async {
    for (final s in _subs) {
      s.close();
    }
    container.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  }
}
