import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_registry.dart';
import '../../extension/state/registry_entries.dart';

/// Now Playing route, queue nav item and playback flush hook. Queue is a
/// placeholder until playback can open the queue.
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
