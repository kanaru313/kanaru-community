import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/online/lyrics_source.dart';
import '../../domain/online/online_search_state.dart';
import '../lyrics_plain_rows.dart';
import '../lyrics_spinner.dart';
import '../online/plugin_avatar.dart';

/// A source that is on in "Nguồn tìm kiếm": a choice with its result count,
/// dimmed and not a choice while it has no results.
class SourceChoiceRow extends StatelessWidget {
  const SourceChoiceRow({
    super.key,
    required this.source,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final LyricsSource source;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SelectionRow(
      leading: PluginAvatar(
        providerId: source.id,
        name: source.name,
        size: KIconSize.md,
      ),
      title: Text(source.name),
      subtitle: Text(
        count > 0
            ? l10n.lyricsPickerSourcesResults(count)
            : l10n.lyricsPickerSourcesNone,
      ),
      enabled: count > 0,
      selected: selected,
      onTap: onTap,
    );
  }
}

/// A source that is off: a choice once it was asked and has results, a
/// spinner while it is asked, else a row with [Tìm].
class OffSourceRow extends StatelessWidget {
  const OffSourceRow({
    super.key,
    required this.source,
    required this.part,
    required this.count,
    required this.selected,
    required this.onChoose,
    required this.onSearch,
  });

  final LyricsSource source;
  final SourceSearch? part;
  final int count;
  final bool selected;
  final VoidCallback onChoose;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatar = PluginAvatar(
      providerId: source.id,
      name: source.name,
      size: KIconSize.md,
    );
    final part = this.part;
    if (part != null && part.phase != SourceSearchPhase.loading) {
      return SelectionRow(
        leading: avatar,
        title: Text(source.name),
        subtitle: Text(
          count > 0
              ? l10n.lyricsPickerSourcesOffResults(count)
              : l10n.lyricsPickerSourcesNone,
        ),
        enabled: count > 0,
        selected: selected,
        onTap: onChoose,
      );
    }
    final loading = part != null;
    return LyricsPlainRows(
      child: KListRow(
        leading: avatar,
        title: Text(source.name),
        subtitle: Text(l10n.lyricsPickerSourcesNotAsked),
        trailing: loading
            ? LyricsSpinner(
                size: KIconSize.sm,
                color: Theme.of(context).colorScheme.primary,
                label: l10n.lyricsPickerSearching(source.name),
              )
            : KModalButton(
                label: l10n.lyricsPickerMoreAction,
                emphasis: KModalEmphasis.tonal,
                onPressed: onSearch,
              ),
      ),
    );
  }
}
