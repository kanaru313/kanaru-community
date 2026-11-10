import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../extension/state/extension_providers.dart';
import '../../screens/first_run/state/first_run_gate.dart';
import '../app_router.dart';

/// The app router, built once from the registry. It re-evaluates its redirect
/// whenever [firstRunRequiredProvider] changes.
final routerProvider = Provider<GoRouter>((ref) {
  final gate = ValueNotifier<bool>(ref.read(firstRunRequiredProvider));
  ref.listen<bool>(firstRunRequiredProvider, (_, next) => gate.value = next);
  final router = buildRouter(
    ref.watch(extensionRegistryProvider),
    firstRunRequired: () => gate.value,
    refresh: gate,
  );
  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});
