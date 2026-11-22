import 'package:flutter/foundation.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import 'swap_title.dart';

/// `[←] · title · actions` of the plugin page. The title is "Chi tiết plugin"
/// and changes to [name] while [collapsed] is true (the head card has
/// scrolled out). A page in a state (loading, error, gone) passes a null
/// [name] and keeps the first title.
class PluginPageHeader extends StatelessWidget {
  const PluginPageHeader({
    super.key,
    required this.collapsed,
    required this.name,
    required this.onBack,
    this.actions = const [],
  });

  final ValueListenable<bool> collapsed;
  final String? name;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = PageHeaderScope.of(context);
    return SizedBox(
      height: KLayout.minTarget + KSpace.x2,
      child: Row(
        spacing: KSpace.x2,
        children: [
          if (onBack != null)
            KIconButton(
              icon: KIcons.back,
              tooltip: l10n.tooltipBack,
              onPressed: onBack,
            ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: collapsed,
              builder: (_, value, _) => SwapTitle(
                first: l10n.pluginsPageTitle,
                second: name,
                showSecond: value,
              ),
            ),
          ),
          ...actions,
          ...?scope?.trailing,
        ],
      ),
    );
  }
}
