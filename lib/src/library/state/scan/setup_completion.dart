import '../../../platform/domain/settings_store.dart';
import '../../../platform/state/settings_providers.dart';
import '../../domain/scan_status.dart';

/// Finishes the first-run setup: marks it done, asks for the first scan and
/// flushes the settings to disk.
///
/// Setting `library.setup_done` re-runs the router redirect at once and
/// disposes the setup page, so the caller reads its dependencies *before*
/// calling this and nothing here touches a widget reference. The order
/// matters: the store updates its memory in the first step, so the scan
/// request that follows already sees setup as done and is accepted.
///
/// Throws what the store throws when it cannot write.
Future<void> completeSetup({
  required SettingNotifier<bool> setupDone,
  required LibraryScanCommands scan,
  required SettingsStore store,
}) async {
  final saved = setupDone.set(true);
  final scanning = scan.rescan();
  await saved;
  await scanning;
  await store.flush();
}
