import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/extension/domain/license.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:logging/logging.dart';

const _chat = ProFeature('test.chat');
const _sync = ProFeature('test.sync');

/// A license whose answers change while the app runs, reported on [changes].
class _License implements LicenseService {
  _License({bool sync = false})
    : _changes = StreamController<void>.broadcast(sync: sync);

  final StreamController<void> _changes;
  final granted = <ProFeature>{};
  var asked = 0;

  bool get hasListener => _changes.hasListener;

  void grant(ProFeature feature) {
    granted.add(feature);
    _changes.add(null);
  }

  void revoke(ProFeature feature) {
    granted.remove(feature);
    _changes.add(null);
  }

  void fail() => _changes.addError(StateError('license store unreadable'));

  @override
  LicenseStatus statusOf(ProFeature feature) {
    asked++;
    return granted.contains(feature)
        ? LicenseStatus.granted
        : LicenseStatus.locked;
  }

  @override
  Stream<void> get changes => _changes.stream;

  Future<void> close() => _changes.close();
}

/// A license whose `changes` breaks the contract: single-subscription.
class _SingleSubscriptionLicense implements LicenseService {
  final _changes = StreamController<void>();

  @override
  LicenseStatus statusOf(ProFeature feature) => LicenseStatus.locked;

  @override
  Stream<void> get changes => _changes.stream;
}

/// Warnings logged by the license providers while [body] runs.
Future<List<LogRecord>> _licenseWarnings(Future<void> Function() body) async {
  final records = <LogRecord>[];
  final sub = Logger.root.onRecord
      .where((r) => r.loggerName == 'license' && r.level >= Level.WARNING)
      .listen(records.add);
  try {
    await body();
  } finally {
    await sub.cancel();
  }
  return records;
}

class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

ProviderContainer _container(_License license) {
  final container = ProviderContainer(
    overrides: [licenseServiceProvider.overrideWithValue(license)],
  );
  addTearDown(() async {
    container.dispose();
    await license.close();
  });
  return container;
}

void main() {
  test('answers the new status after the license reports a change', () async {
    final license = _License();
    final container = _container(license);
    expect(
      container.read(proFeatureStatusProvider(_chat)),
      LicenseStatus.locked,
    );

    license.grant(_chat);
    await pumpEventQueue();
    expect(
      container.read(proFeatureStatusProvider(_chat)),
      LicenseStatus.granted,
    );

    license.revoke(_chat);
    await pumpEventQueue();
    expect(
      container.read(proFeatureStatusProvider(_chat)),
      LicenseStatus.locked,
    );
  });

  test('two features and two listeners each follow the change', () async {
    final license = _License();
    final container = _container(license);
    final chatA = <LicenseStatus>[];
    final chatB = <LicenseStatus>[];
    final sync = <LicenseStatus>[];
    container
      ..listen(proFeatureStatusProvider(_chat), (_, s) => chatA.add(s))
      ..listen(proFeatureStatusProvider(_chat), (_, s) => chatB.add(s))
      ..listen(proFeatureStatusProvider(_sync), (_, s) => sync.add(s));

    license.grant(_chat);
    await pumpEventQueue();
    expect(chatA, [LicenseStatus.granted]);
    expect(chatB, [LicenseStatus.granted]);
    expect(sync, isEmpty, reason: 'its answer did not change');

    license.grant(_sync);
    await pumpEventQueue();
    expect(sync, [LicenseStatus.granted]);
    expect(chatA, [LicenseStatus.granted], reason: 'no new value to report');
  });

  test('a synchronous license works the same', () async {
    final license = _License(sync: true);
    final container = _container(license);
    final seen = <LicenseStatus>[];
    container.listen(proFeatureStatusProvider(_chat), (_, s) => seen.add(s));

    license.grant(_chat);
    await pumpEventQueue();
    expect(seen, [LicenseStatus.granted]);
  });

  test('an error on the stream re-asks and keeps listening', () async {
    final license = _License();
    final container = _container(license);
    final seen = <LicenseStatus>[];
    container.listen(proFeatureStatusProvider(_chat), (_, s) => seen.add(s));
    final askedBefore = license.asked;

    license.fail();
    await pumpEventQueue();
    expect(license.asked, greaterThan(askedBefore));

    license.grant(_chat);
    await pumpEventQueue();
    expect(seen, [LicenseStatus.granted]);
  });

  test('disposing the container stops listening to the license', () async {
    final license = _License();
    final container = ProviderContainer(
      overrides: [licenseServiceProvider.overrideWithValue(license)],
    );
    addTearDown(license.close);
    container
      ..read(proFeatureStatusProvider(_chat))
      ..read(proFeatureStatusProvider(_sync));
    expect(license.hasListener, isTrue);

    container.dispose();
    expect(license.hasListener, isFalse);
  });

  test('the Free license never changes', () async {
    const free = FreeLicenseService();
    expect(free.changes.isBroadcast, isTrue);
    await expectLater(free.changes, emitsDone);

    final container = ProviderContainer(
      overrides: [licenseServiceProvider.overrideWithValue(free)],
    );
    addTearDown(container.dispose);
    expect(
      container.read(proFeatureStatusProvider(_chat)),
      LicenseStatus.locked,
    );
  });

  test('a single-subscription changes stream is refused', () {
    final container = ProviderContainer(
      overrides: [
        licenseServiceProvider.overrideWithValue(_SingleSubscriptionLicense()),
      ],
    );
    addTearDown(container.dispose);
    expect(
      () => container.read(proFeatureStatusProvider(_chat)),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('broadcast'),
          ),
        ),
      ),
    );
  });

  test('a closed stream keeps the last answer and is logged once', () async {
    final license = _License()..granted.add(_chat);
    final container = _container(license);
    final warnings = await _licenseWarnings(() async {
      container
        ..read(proFeatureStatusProvider(_chat))
        ..read(proFeatureStatusProvider(_sync));
      await license.close();
      await pumpEventQueue();
    });

    expect(warnings, hasLength(1));
    expect(warnings.single.message, contains('stopped reporting changes'));
    expect(
      container.read(proFeatureStatusProvider(_chat)),
      LicenseStatus.granted,
    );
    expect(
      container.read(proFeatureStatusProvider(_sync)),
      LicenseStatus.locked,
    );
  });

  test('the Free license closing logs nothing', () async {
    final container = ProviderContainer(
      overrides: [
        licenseServiceProvider.overrideWithValue(const FreeLicenseService()),
      ],
    );
    addTearDown(container.dispose);
    final warnings = await _licenseWarnings(() async {
      container.read(proFeatureStatusProvider(_chat));
      await pumpEventQueue();
    });
    expect(warnings, isEmpty);
  });

  test('a synchronous change while another provider builds settles', () async {
    final license = _License(sync: true);
    final container = _container(license);
    // Builds on the feature's status, then changes the license from inside
    // its own build, as a Pro provider that refreshes the license might.
    final dependent = Provider<LicenseStatus>((ref) {
      final status = ref.watch(proFeatureStatusProvider(_chat));
      if (!license.granted.contains(_chat)) license.grant(_chat);
      return status;
    });
    final seen = <LicenseStatus>[];
    container.listen(dependent, (_, s) => seen.add(s), fireImmediately: true);

    await pumpEventQueue();
    expect(container.read(dependent), LicenseStatus.granted);
    expect(
      container.read(proFeatureStatusProvider(_chat)),
      LicenseStatus.granted,
    );
    expect(seen.last, LicenseStatus.granted);
  });

  test('a synchronous change from a listener during a build settles', () async {
    final license = _License(sync: true);
    final container = _container(license);
    // A provider that a status watcher depends on changes the license from
    // a listener fired while the status watcher is being built.
    final trigger = NotifierProvider<_Counter, int>(_Counter.new);
    final watcher = Provider<LicenseStatus>((ref) {
      ref.listen(trigger, (_, _) => license.grant(_chat));
      return ref.watch(proFeatureStatusProvider(_chat));
    });
    container.listen(watcher, (_, _) {});

    container.read(trigger.notifier).bump();
    await pumpEventQueue();
    expect(container.read(watcher), LicenseStatus.granted);
  });
}
