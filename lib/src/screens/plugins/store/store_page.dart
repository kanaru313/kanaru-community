import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_filter.dart';
import '../../../plugins/state/store_ops.dart';
import '../../../plugins/state/store_view_provider.dart';
import '../../settings/settings_routes.dart';
import '../../settings/ui/settings_scaffold.dart';
import '../common/plugin_labels.dart';
import '../common/restore_trigger.dart';
import 'store_actions.dart';
import 'store_banners.dart';
import 'store_empty.dart';
import 'store_filter_sheet.dart';
import 'store_filter_toggles.dart';
import 'store_menu.dart';
import 'store_sections.dart';

/// Kho plugin: one list under a pinned header and search, in the blocks
/// Cập nhật → Đã cài → Chưa cài. Opening it starts from a fresh filter
/// ([kind] presets Lọc › Loại), refreshes the stale repositories and retries
/// the plugins that were missing their package.
class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key, this.kind});

  /// The `kind` query of the route: `lyrics`, `translate` or `streaming`.
  final String? kind;

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage> {
  final _search = TextEditingController();
  final _filterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Providers cannot change while the tree builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(storeFilterProvider.notifier)
          .set(
            StoreFilterToggles.preset(StoreKindGroup.fromQuery(widget.kind)),
          );
      unawaited(ref.read(storeOpsProvider).onOpen());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(storeViewProvider);
    final repos = ref.watch(repoViewsProvider).value ?? const <RepoView>[];
    final filter = ref.watch(storeFilterProvider);
    final actions = ref.watch(storeActionsProvider);
    watchPluginRestore(ref);
    // "Xoá bộ lọc" and a route preset change the query without typing.
    ref.listen(storeFilterProvider, (_, next) {
      if (next.query != _search.text) _search.text = next.query;
    });
    final bare = view.value?.isBare ?? false;
    return SettingsScaffold(
      title: l10n.pluginsStoreTitle,
      parentPath: SettingsPaths.root,
      actions: [_filterButton(l10n, filter), _moreButton(l10n, actions, repos)],
      pinnedBelowHeader: bare ? null : _searchField(l10n, filter),
      // The list rows are list items of their own, so the page spaces them.
      spaced: false,
      children: [
        if (repos.any((r) => r.errorKind != null)) ...[
          StoreBanner(repos: repos),
          const KGap(KSpace.x5),
        ],
        ..._body(context, view, actions, filter),
      ],
    );
  }

  Widget _filterButton(AppLocalizations l10n, StoreFilter filter) {
    final count = filter.valueCount;
    return KeyedSubtree(
      key: _filterKey,
      child: KIconButton(
        icon: KIcons.filter,
        tooltip: l10n.pluginsFilterTooltip,
        selected: count > 0,
        badgeCount: count,
        badgeSemanticLabel: count > 0
            ? l10n.pluginsFilterActiveLabel(count)
            : null,
        onPressed: () => showStoreFilter(context, _filterKey),
      ),
    );
  }

  Widget _moreButton(
    AppLocalizations l10n,
    StoreActions actions,
    List<RepoView> repos,
  ) => KMoreButton(
    tooltip: l10n.pluginsMenuTooltip,
    onPressed: ({required viaKeyboard}) => showStoreMenu(
      context,
      actions: actions,
      repoCount: repos.length,
      viaKeyboard: viaKeyboard,
      onRefreshAll: () => unawaited(ref.read(storeOpsProvider).refreshAll()),
    ),
  );

  Widget _searchField(AppLocalizations l10n, StoreFilter filter) =>
      KFilterField(
        controller: _search,
        hint: l10n.pluginsSearchHint,
        closeTooltip: l10n.pluginsSearchClear,
        persistent: true,
        onClose: () {},
        onChanged: (text) => ref
            .read(storeFilterProvider.notifier)
            .set(ref.read(storeFilterProvider).copyWith(query: text)),
      );

  List<Widget> _body(
    BuildContext context,
    AsyncValue<StoreView> view,
    StoreActions actions,
    StoreFilter filter,
  ) {
    final l10n = AppLocalizations.of(context);
    if (view.hasError) {
      return [
        KInlineNotice(
          icon: KIcons.warning,
          tone: KInlineNoticeTone.errorFilled,
          message: l10n.pluginsLoadFailed,
        ),
      ];
    }
    final data = view.value;
    if (data == null) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: KSpace.x7),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (data.isBare) return [NoRepositoryCard(actions: actions)];
    if (data.noMatch) {
      return [
        NoMatchNotice(
          onClear: filter.isEmpty
              ? null
              : () => ref.read(storeFilterProvider.notifier).clear(),
        ),
      ];
    }
    return storeSectionWidgets(context, data, actions);
  }
}
