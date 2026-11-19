import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../platform/state/settings_save_status_provider.dart';
import '../../first_run/ui/folder_sheet_states.dart';

/// Frame of every Settings page: [KPage] column, header, the save-failure
/// banner, then [children] separated by block spacing. A page with a
/// [parentPath] shows a back arrow that leads there when there is no history.
class SettingsScaffold extends ConsumerWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.children,
    this.parentPath,
  });

  final String title;
  final List<Widget> children;

  /// Where the header back arrow goes when the page was opened directly.
  /// Null on the root, which has no arrow of its own.
  final String? parentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final failing = ref.watch(settingsSaveFailingProvider).value ?? false;
    final parent = parentPath;
    return KPage(
      maxWidth: KLayout.settings,
      children: [
        PageHeader(
          title: title,
          onBack: parent == null ? null : () => _back(context, parent),
          backTooltip: parent == null ? null : l10n.tooltipBack,
        ),
        if (failing) ...[
          FolderSheetBanner(
            icon: KIcons.permissionMissing,
            isError: true,
            child: Text(l10n.settingsSaveFailed),
          ),
          const KGap(KSpace.x5),
        ],
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const KGap(KSpace.x5),
          children[i],
        ],
      ],
    );
  }

  static void _back(BuildContext context, String parent) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(parent);
    }
  }
}

/// One card of rows without a title, as the root page groups them.
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: KShape.of(KRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
