import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_providers.dart';
import '../state/nav_history.dart';

/// 40 dp bar above everything: navigation on the left, app name in the middle,
/// extension actions on the right.
class DesktopTopBar extends ConsumerWidget {
  const DesktopTopBar({
    super.key,
    required this.history,
    required this.onToggleSidebar,
    required this.onHome,
  });

  final NavHistory history;
  final VoidCallback onToggleSidebar;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final actions = ref.watch(extensionRegistryProvider).topBarActions;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        height: KLayout.minTargetDesktop,
        child: ListenableBuilder(
          listenable: history,
          builder: (context, _) => Row(
            children: [
              const SizedBox(width: KSpace.x2),
              _BarButton(
                icon: KIcons.sidebarToggle,
                tooltip: l10n.tooltipToggleSidebar,
                onPressed: onToggleSidebar,
              ),
              _BarButton(
                icon: KIcons.back,
                tooltip: l10n.tooltipBack,
                onPressed: history.canGoBack ? history.back : null,
              ),
              _BarButton(
                icon: KIcons.forward,
                tooltip: l10n.tooltipForward,
                onPressed: history.canGoForward ? history.forward : null,
              ),
              _BarButton(
                icon: KIcons.home,
                tooltip: l10n.tooltipHome,
                onPressed: onHome,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: KSpace.x2,
                  children: [
                    Icon(KIcons.appLogo, size: KSpace.x5, color: scheme.primary),
                    Text('Kanaru', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              for (final action in actions) action.builder(context),
              const SizedBox(width: KSpace.x2),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: KSpace.x5,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: KLayout.minTargetDesktop,
        height: KLayout.minTargetDesktop,
      ),
      onPressed: onPressed,
    );
  }
}
