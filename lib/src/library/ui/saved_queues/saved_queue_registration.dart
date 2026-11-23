import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../extension/state/registry_entries.dart';
import '../library_locations.dart';

/// The "Queue" sidebar item and hub tile: a child of the Playlist tab that
/// opens the saved queues. Registered by `registerPlaylists` right after the
/// tab (the parent goes first). Its id is the one the hub and the sidebar
/// look up.
NavItem savedQueuesNavItem() => NavItem(
  id: 'queue',
  path: LibraryLocations.savedQueues,
  icon: KIcons.queue,
  selectedIcon: KIcons.queue,
  label: (c) => AppLocalizations.of(c).playbackNavQueue,
  order: 230,
  mobileTab: false,
  parentId: 'playlists',
);
