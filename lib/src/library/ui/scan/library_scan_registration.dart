import '../../../extension/state/extension_registry.dart';

/// Scan-related contributions (settings section, startup hooks).
///
/// Empty on purpose: there is no Settings › Library page yet (it needs its
/// own mockup), and the startup scan is started by Home through
/// `ScanController.ensureStartupWork`, not by a hook (a hook only receives a
/// database connection).
void registerLibraryScan(ExtensionRegistry registry) {}
