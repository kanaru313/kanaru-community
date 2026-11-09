import '../extension/kanaru_extension.dart';
import '../extension/state/extension_registry.dart';
import 'ui/library_browse_registration.dart';
import 'ui/scan/library_scan_registration.dart';

/// Library and Playlists: nav entries and root pages. Each concern registers
/// from its own file.
class LibraryExtension implements KanaruExtension {
  const LibraryExtension();

  @override
  String get id => 'library';

  @override
  void register(ExtensionRegistry registry) {
    registerLibraryBrowse(registry);
    registerLibraryScan(registry);
  }
}
