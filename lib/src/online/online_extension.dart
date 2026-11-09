import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../extension/kanaru_extension.dart';
import '../extension/state/extension_registry.dart';
import '../extension/state/registry_entries.dart';
import 'ui/online_page.dart';

/// Online sources: nav entry and root page.
class OnlineExtension implements KanaruExtension {
  const OnlineExtension();

  @override
  String get id => 'online';

  @override
  void register(ExtensionRegistry registry) {
    registry
      ..addNavItem(NavItem(
        id: 'online',
        path: '/online',
        icon: KIcons.online,
        selectedIcon: KIcons.onlineSelected,
        label: (c) => AppLocalizations.of(c).navOnline,
        order: 50,
      ))
      ..addRoute(GoRoute(path: '/online', builder: (_, _) => const OnlinePage()));
  }
}
