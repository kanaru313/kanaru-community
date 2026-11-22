import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_filter.dart';
import '../../../plugins/state/store_ops.dart';
import '../../../plugins/state/store_view_provider.dart';
import '../common/plugin_labels.dart';
import 'store_filter_toggles.dart';

/// Content of the Lọc sheet / panel. Every tap filters the list at once; the
/// footer says how many plugins show.
class StoreFilterBody extends ConsumerWidget {
  const StoreFilterBody({super.key, required this.raised});

  /// The body sits on a raised surface (the desktop panel), so unselected
  /// chips stand out from it.
  final bool raised;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(storeFilterProvider);
    // Each tap edits the filter as it is now, not as it was when this built.
    void edit(StoreFilter Function(StoreFilter) change) => ref
        .read(storeFilterProvider.notifier)
        .set(change(ref.read(storeFilterProvider)));
    final facets = ref.watch(storeFacetsProvider);
    final repos = ref.watch(repoViewsProvider).value ?? const [];
    final shown = ref.watch(storeViewProvider).value?.shownCount ?? 0;
    final languages = [
      ...facets.languages,
    ]..sort((a, b) => languageLabel(l10n, a).compareTo(languageLabel(l10n, b)));

    Widget chip(String label, bool on, VoidCallback tap, {String? tip}) {
      final c = KChip(
        label: Text(label),
        selected: on,
        dense: true,
        onRaised: raised,
        onTap: tap,
      );
      return tip == null ? c : Tooltip(message: tip, child: c);
    }

    final groups = <(String, List<Widget>)>[
      (
        l10n.pluginsFilterGroupKind,
        [
          for (final g in StoreKindGroup.values)
            chip(
              kindGroupLabel(l10n, g),
              filter.hasKind(g),
              () => edit((f) => f.toggleKind(g)),
              tip: kindGroupHelp(l10n, g),
            ),
        ],
      ),
      (
        l10n.pluginsFilterGroupState,
        [
          for (final s in StoreStateChip.values)
            chip(
              _stateLabel(l10n, s),
              filter.hasState(s),
              () => edit((f) => f.toggleState(s)),
            ),
        ],
      ),
      (
        l10n.pluginsFilterGroupLanguage,
        [
          for (final key in languages)
            chip(
              languageLabel(l10n, key),
              filter.languages.contains(key),
              () => edit((f) => f.toggleLanguage(key)),
            ),
        ],
      ),
      (
        l10n.pluginsFilterGroupAuthor,
        [
          for (final author in facets.authors)
            chip(
              author,
              filter.authors.contains(author),
              () => edit((f) => f.toggleAuthor(author)),
            ),
        ],
      ),
      (
        l10n.pluginsFilterGroupRepository,
        [
          for (final repo in repos)
            chip(
              repo.name,
              filter.repoIds.contains(repo.id),
              () => edit((f) => f.toggleRepo(repo.id)),
            ),
        ],
      ),
    ];
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x6,
            KSpace.x4,
            KSpace.x6,
            KSpace.x2,
          ),
          child: Text(l10n.pluginsFilterTitle, style: text.titleMedium),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: KSpace.x6,
              vertical: KSpace.x2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (title, chips) in groups)
                  if (chips.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: KSpace.x2),
                      child: Semantics(
                        header: true,
                        child: Text(title, style: text.titleSmall),
                      ),
                    ),
                    Wrap(
                      spacing: KSpace.x2,
                      runSpacing: KSpace.x2,
                      children: chips,
                    ),
                    const KGap(KSpace.x4),
                  ],
              ],
            ),
          ),
        ),
        PickerFooter(
          note: Text(l10n.pluginsFilterShowing(shown)),
          buttons: [
            TextButton(
              onPressed: filter.valueCount == 0
                  ? null
                  : () => edit((f) => f.withoutValues),
              child: Text(l10n.pluginsFilterClearAll),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.pluginsFilterDone),
            ),
          ],
        ),
      ],
    );
  }

  static String _stateLabel(AppLocalizations l10n, StoreStateChip chip) =>
      switch (chip) {
        StoreStateChip.installed => l10n.pluginsStateInstalled,
        StoreStateChip.notInstalled => l10n.pluginsStateNotInstalled,
        StoreStateChip.updatable => l10n.pluginsStateUpdatable,
      };
}
