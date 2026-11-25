import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../domain/license.dart';
import 'extension_registry.dart';

/// Overridden by `runKanaru` with the filled registry.
final extensionRegistryProvider = Provider<ExtensionRegistry>(
  (ref) =>
      throw UnimplementedError('extensionRegistryProvider must be overridden'),
);

final licenseServiceProvider = Provider<LicenseService>(
  (ref) => ref.watch(extensionRegistryProvider).licenseService,
);

final _log = Logger('license');

/// Services whose closed `changes` stream was already logged, so a closed
/// stream is reported once, not once per feature.
final _closedReported = Expando<bool>('license changes closed');

/// The status of one Pro feature: the one way UI and state code read it.
///
/// It follows the license's `changes`: on every event (or stream error) it is
/// rebuilt and asks `statusOf` again, so watchers update while the app runs
/// and `ref.read` always gets the current answer. If `changes` closes, the
/// last answer stays.
final proFeatureStatusProvider = Provider.family<LicenseStatus, ProFeature>((
  ref,
  feature,
) {
  final service = ref.watch(licenseServiceProvider);
  final changes = service.changes;
  assert(
    changes.isBroadcast,
    'LicenseService.changes must be a broadcast stream: every Pro feature '
    'listens to it, and listeners come and go while the app runs.',
  );
  // Ask first, then listen: nothing runs between the two, so no change falls
  // in the gap, and the provider never invalidates itself while building.
  final status = service.statusOf(feature);
  final sub = changes.listen(
    (_) => ref.invalidateSelf(),
    onError: (Object error, StackTrace stack) {
      // The status may be unknown now: ask again rather than keep a stale one.
      _log.warning('License changes stream failed', error, stack);
      ref.invalidateSelf();
    },
    onDone: () {
      // The Free license closes at once by design: it never changes.
      if (service is FreeLicenseService || _closedReported[service] == true) {
        return;
      }
      _closedReported[service] = true;
      _log.warning(
        'License stopped reporting changes; Pro features keep their last status',
      );
    },
  );
  ref.onDispose(sub.cancel);
  return status;
});
