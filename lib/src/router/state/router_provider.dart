import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../extension/state/extension_providers.dart';
import '../app_router.dart';

/// The app router, built once from the registry.
final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref.watch(extensionRegistryProvider));
  ref.onDispose(router.dispose);
  return router;
});
