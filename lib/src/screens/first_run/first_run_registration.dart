import 'package:go_router/go_router.dart';

import '../../extension/state/extension_registry.dart';
import 'state/first_run_gate.dart';
import 'ui/first_run_page.dart';

/// The first-run route, top level (outside the shell), served at
/// [firstRunPath]. The router redirects here while setup is not done.
void registerFirstRun(ExtensionRegistry registry) {
  registry.addRoute(
    GoRoute(path: firstRunPath, builder: (_, _) => const FirstRunPage()),
  );
}
