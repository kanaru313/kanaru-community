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
    this.pinnedBelowHeader,
    this.headerBuilder,
    this.actions = const [],
    this.spaced = true,
    this.maxWidth = KLayout.settings,
  });

  final String title;
  final List<Widget> children;

  /// Where the header back arrow goes when the page was opened directly.
  /// Null on the root, which has no arrow of its own.
  final String? parentPath;

  /// Stays fixed under the header while [children] scroll (a search field).
  /// Null keeps the whole page in one scroll view, header included.
  final Widget? pinnedBelowHeader;

  /// Draws the header instead of the standard one (a title that changes while
  /// the page scrolls). It gets the back action (null on a root page) and the
  /// header stays fixed while [children] scroll, like with
  /// [pinnedBelowHeader]. [title] and [actions] are not used then.
  final Widget Function(BuildContext context, VoidCallback? onBack)?
  headerBuilder;

  /// Buttons at the end of the header (a filter and a ⋮ menu).
  final List<Widget> actions;

  /// True puts block spacing between [children]. A long list that is its own
  /// list items (one per row) sets false and draws its own gaps.
  final bool spaced;

  /// Content width cap on wide windows; only a page with a card grid asks
  /// for [KLayout.settingsWide].
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final failing = ref.watch(settingsSaveFailingProvider).value ?? false;
    final parent = parentPath;
    final pinned = pinnedBelowHeader;
    if (pinned != null || headerBuilder != null) {
      return _pinnedLayout(context, l10n, failing, pinned);
    }
    return KPage(
      maxWidth: maxWidth,
      children: [
        PageHeader(
          title: title,
          onBack: parent == null ? null : () => _back(context, parent),
          backTooltip: parent == null ? null : l10n.tooltipBack,
          actions: actions,
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
          if (spaced && i > 0) const KGap(KSpace.x5),
          children[i],
        ],
      ],
    );
  }

  Widget _pinnedLayout(
    BuildContext context,
    AppLocalizations l10n,
    bool failing,
    Widget? pinned,
  ) {
    final parent = parentPath;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final gutter = desktop ? KLayout.gutterDesktop : KLayout.gutterMobile;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (headerBuilder != null)
                      headerBuilder!(
                        context,
                        parent == null ? null : () => _back(context, parent),
                      )
                    else
                      PageHeader(
                        title: title,
                        onBack: parent == null
                            ? null
                            : () => _back(context, parent),
                        backTooltip: parent == null ? null : l10n.tooltipBack,
                        actions: actions,
                      ),
                    ?pinned,
                    const KGap(KSpace.x2),
                  ],
                ),
              ),
            ),
            Expanded(
              child: KPage(
                maxWidth: maxWidth,
                children: [
                  if (failing) ...[
                    FolderSheetBanner(
                      icon: KIcons.permissionMissing,
                      isError: true,
                      child: Text(l10n.settingsSaveFailed),
                    ),
                    const KGap(KSpace.x5),
                  ],
                  for (var i = 0; i < children.length; i++) ...[
                    if (spaced && i > 0) const KGap(KSpace.x5),
                    children[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
