import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/online/lyrics_match.dart';
import '../../domain/online/online_search_state.dart';
import 'picker_view.dart';
import 'picker_more_cards.dart';
import 'picker_result_row.dart';
import 'picker_source_notes.dart';

/// The results of the picker grouped by source: a group title, then the
/// results, or the source's loading / failure line. After them the card that
/// offers the sources that are off; with nothing to list, the empty state.
class PickerResults extends StatelessWidget {
  const PickerResults({
    super.key,
    required this.view,
    required this.selected,
    required this.onResult,
    required this.onSearchOff,
    required this.closePicker,
  });

  final PickerView view;

  /// The chosen result of the desktop list; null on the touch shells.
  final ResultRef? selected;
  final void Function(PickerGroup group, LyricsMatch match) onResult;

  /// Asks the sources that are off, now.
  final VoidCallback onSearchOff;
  final bool Function() closePicker;

  static bool _hasContent(PickerGroup g) => switch (g.part.phase) {
    SourceSearchPhase.empty => false,
    SourceSearchPhase.results => g.part.matches.isNotEmpty,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (view.waiting) {
      return Align(
        alignment: Alignment.topCenter,
        child: PickerLoadingNote(label: l10n.lyricsSearchingTitle),
      );
    }
    final visible = view.visible;
    if (!visible.any(_hasContent)) {
      return PickerEmpty(
        enabledCount: view.enabledCount,
        pending: view.filter == null ? view.pending : const [],
        onSearchOff: view.filter == null ? onSearchOff : null,
      );
    }
    final all = view.filter == null;
    final selectable = FormFactor.of(context) == FormFactor.desktop;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x2),
      children: [
        for (final g in visible) ..._group(context, g, selectable),
        if (all && view.pending.isNotEmpty)
          PickerMoreCard(pending: view.pending, onSearch: onSearchOff)
        else if (all && view.askedOff && !view.searching)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              KSpace.x3,
              KSpace.x4,
              KSpace.x2,
            ),
            child: Text(
              l10n.lyricsPickerAllAsked,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _group(BuildContext context, PickerGroup g, bool selectable) {
    final name = g.source.name;
    final l10n = AppLocalizations.of(context);
    switch (g.part.phase) {
      case SourceSearchPhase.empty:
        return const [];
      case SourceSearchPhase.loading:
        return [PickerLoadingNote(label: l10n.lyricsPickerSearching(name))];
      case SourceSearchPhase.failed:
      case SourceSearchPhase.needsConfig:
      case SourceSearchPhase.paused:
        return [
          PickerFailureNote(
            sourceId: g.source.id,
            name: name,
            part: g.part,
            closePicker: closePicker,
          ),
        ];
      case SourceSearchPhase.results:
        final count = g.part.matches.length;
        return [
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                KSpace.x6,
                KSpace.x3,
                KSpace.x6,
                KSpace.x1,
              ),
              child: Text(
                g.off
                    ? l10n.lyricsPickerGroupOff(name, count)
                    : l10n.lyricsPickerGroup(name, count),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          for (final m in g.part.matches)
            PickerResultRow(
              key: ValueKey(
                '${m.candidate.providerId}:${m.candidate.remoteId}',
              ),
              candidate: m.candidate,
              sourceName: name,
              sourceOff: g.off,
              songDuration: view.songDuration,
              selected: selectable && selected == m.candidate.ref,
              onTap: () => onResult(g, m),
            ),
        ];
    }
  }
}
