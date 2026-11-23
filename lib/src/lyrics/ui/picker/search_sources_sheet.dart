import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../state/online/lyrics_sources_provider.dart';
import 'picker_controller.dart';
import 'picker_view.dart';
import 'search_sources_rows.dart';

/// Opens "Nguồn tìm kiếm" over the picker: which source the list shows. A
/// bottom sheet on the touch shells, a dialog from 600 dp.
Future<void> showSearchSourcesSheet(BuildContext context, TrackId trackId) =>
    showKSheet<void>(
      context,
      useRootNavigator: true,
      builder: (_) => SearchSourcesSheet(trackId: trackId),
    );

/// "Tất cả nguồn" and every source with its result count; the sources that
/// are off follow under their own title and are searched only with [Tìm].
/// Choosing a row sets the picker's filter and closes the sheet.
class SearchSourcesSheet extends ConsumerWidget {
  const SearchSourcesSheet({super.key, required this.trackId});

  final TrackId trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(pickerViewProvider(trackId));
    final sources = ref.watch(lyricsSourcesProvider);
    final controller = ref.read(pickerControllerProvider(trackId).notifier);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final byId = {for (final g in view.groups) g.source.id: g.part};
    int count(String id) => byId[id]?.matches.length ?? 0;
    final total = view.groups.fold<int>(0, (n, g) => n + count(g.source.id));

    void choose(String? id) {
      controller.setFilter(id);
      Navigator.of(context).pop();
    }

    final off = [
      for (final s in sources)
        if (!s.enabled) s,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x6,
            KSpace.x2,
            KSpace.x2,
            KSpace.x2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.lyricsPickerSourcesTitle,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              KIconButton(
                icon: KIcons.close,
                tooltip: l10n.lyricsModalClose,
                padding: const EdgeInsets.all(KSpace.x3),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectionRow(
                  leading: const Icon(KIcons.selectAll),
                  title: Text(l10n.lyricsPickerSourcesAll),
                  subtitle: Text(l10n.lyricsPickerSourcesResults(total)),
                  selected: view.filter == null,
                  onTap: () => choose(null),
                ),
                for (final s in sources)
                  if (s.enabled)
                    SourceChoiceRow(
                      source: s,
                      count: count(s.id),
                      selected: view.filter == s.id,
                      onTap: () => choose(s.id),
                    ),
                if (off.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KSpace.x6,
                      KSpace.x3,
                      KSpace.x6,
                      0,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.lyricsPickerSourcesOff,
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KSpace.x6,
                      0,
                      KSpace.x6,
                      KSpace.x2,
                    ),
                    child: Text(
                      l10n.lyricsPickerSourcesOffCaption,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final s in off)
                    OffSourceRow(
                      source: s,
                      part: byId[s.id],
                      count: count(s.id),
                      selected: view.filter == s.id,
                      onChoose: () => choose(s.id),
                      onSearch: () => controller.searchDisabled(ids: {s.id}),
                    ),
                ],
                const KGap(KSpace.x2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
