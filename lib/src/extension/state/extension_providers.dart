import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/license.dart';
import 'extension_registry.dart';

/// Overridden by `runKanaru` with the filled registry.
final extensionRegistryProvider = Provider<ExtensionRegistry>(
  (ref) => throw UnimplementedError('extensionRegistryProvider must be overridden'),
);

final licenseServiceProvider = Provider<LicenseService>(
  (ref) => ref.watch(extensionRegistryProvider).licenseService,
);
