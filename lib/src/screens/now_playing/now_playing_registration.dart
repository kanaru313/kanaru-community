import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_registry.dart';
import '../../extension/state/registry_entries.dart';

/// Queue nav item (placeholder). The playback module adds the Now Playing route
/// and the flush hook here.
void registerNowPlaying(ExtensionRegistry registry) {
  registry.addNavItem(
    NavItem(
      id: 'queue',
      path: '/queue',
      icon: KIcons.queue,
      selectedIcon: KIcons.queue,
      label: (c) => AppLocalizations.of(c).playbackNavQueue,
      order: 230,
      mobileTab: false,
      comingSoon: true,
    ),
  );
}
