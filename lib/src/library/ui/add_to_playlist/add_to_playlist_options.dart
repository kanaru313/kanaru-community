import 'package:flutter/foundation.dart' show setEquals;
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../../domain/playlists/playlist_models.dart';
import '../playlist_common/playlist_cover.dart';
import '../playlist_common/playlist_labels.dart';
import 'add_to_playlist_model.dart';
import 'pending_playlist_name_dialog.dart';

/// Everything `showMultiSelectionPicker<String>` needs for the "add to
/// playlist" picker, built from the playlists and per-playlist counts loaded
/// before it opens. Option keys are playlist uids, [PlaylistUids.favorites]
/// or `new:<n>` ([pendingKey]) for a playlist typed in the picker.
///
/// One instance serves one picker: it records the playlists typed in the
/// picker ([pendingNames], typed order) and the uids a failed confirm found
/// deleted ([knownGone]).
class AddToPlaylistPickerContent {
  AddToPlaylistPickerContent({
    required this.l10n,
    required this.request,
    required PlaylistSummaries summaries,
    required Map<String, int> counts,
  }) : _distinct = distinctCount(request.tracks),
       _rows = buildPickerRows(
         playlists: summaries.playlists,
         favorites: summaries.favorites,
         counts: counts,
         excludeUid: request.excludePlaylistUid,
       ),
       _names = {
         for (final s in summaries.playlists) s.uid: s.name,
         summaries.favorites.uid: l10n.playlistFavoritesName,
       };

  final AppLocalizations l10n;
  final AddToPlaylistRequest request;
  final int _distinct;
  final PickerRows _rows;
  final Map<String, String> _names;
  int _typed = 0;

  /// Names of the user's playlists (Favorites has a reserved display name).
  late final List<String> _userNames = [
    for (final e in _names.entries)
      if (e.key != PlaylistUids.favorites) e.value,
  ];

  /// Pending key to typed name, in typed order (a playlist that is created
  /// only if its key is still ticked on confirm).
  final Map<String, String> pendingNames = {};

  /// Uids a previous confirm found deleted.
  final Set<String> knownGone = {};

  /// Display name of every listed playlist and Favorites, by uid.
  Map<String, String> get namesByUid => Map.unmodifiable(_names);

  /// Uids of the playlists that were offered (source excluded), Favorites
  /// included when pinned.
  Iterable<String> get offeredUids => [
    if (_rows.pinned != null) _rows.pinned!.summary.uid,
    for (final r in _rows.rows) r.summary.uid,
  ];

  /// Favorites, above the divider; empty when Favorites is the source.
  List<SelectionOption<String>> get pinned => [
    if (_rows.pinned != null) _option(_rows.pinned!),
  ];

  /// Playlists by date modified, newest first.
  List<SelectionOption<String>> get options => [
    for (final r in _rows.rows) _option(r),
  ];

  /// Title, `Thêm vào playlist`.
  Widget get title => Text(
    l10n.playlistPickerTitle,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  /// Number of distinct songs and where they come from.
  Widget get subtitle => Text(
    request.sourceLabel.isEmpty
        ? l10n.playlistPickerSelectedSongs(_distinct)
        : l10n.playlistPickerSubtitle(_distinct, request.sourceLabel),
    // A long source name must not squeeze the rows out of the fixed sheet.
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  /// Non-null (the picker shows its filter field) above 10 playlists.
  String? get filterHint =>
      showFilter(_rows.rows.length) ? l10n.playlistFilterHint : null;

  String get cancelLabel => l10n.playlistCancel;

  String confirmLabel(Set<String> selected) => selected.length > 1
      ? l10n.playlistPickerAddMany(selected.length)
      : l10n.playlistPickerAdd;

  /// Message of the last failed confirm, shown in the footer while the same
  /// ticks stand (a toast would sit under the mobile sheet).
  final ValueNotifier<String?> _error = ValueNotifier(null);
  Set<String> _errorFor = const {};

  /// Shows [message] in the footer for the ticks [selected].
  void showError(String message, Set<String> selected) {
    _errorFor = {...selected};
    _error.value = message;
  }

  /// Hides the message (the next confirm starts).
  void clearError() => _error.value = null;

  /// The count of ticks, or the error in its colour, announced to screen
  /// readers, until the ticks change.
  Widget footerNote(BuildContext context, Set<String> selected) =>
      ValueListenableBuilder<String?>(
        valueListenable: _error,
        builder: (context, error, _) {
          if (error != null && !setEquals(selected, _errorFor)) {
            // The ticks changed: forget the message for good, so ticking
            // back does not bring it back. Not while building.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!setEquals(selected, _errorFor)) _error.value = null;
            });
          } else if (error != null) {
            return Semantics(
              liveRegion: true,
              container: true,
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          return Text(
            selected.isEmpty
                ? l10n.playlistPickerNoneSelected
                : l10n.playlistPickerSelected(selected.length),
          );
        },
      );

  /// False while every ticked key is a playlist a confirm found deleted.
  bool canConfirm(Set<String> selected) => !selected.every(knownGone.contains);

  /// "Playlist mới…": asks a name and returns the pending option (ticked by
  /// the picker), or null when the dialog is cancelled.
  MultiSelectionAction<String> get leadingAction => MultiSelectionAction(
    title: Text(l10n.playlistPickerNew),
    onPressed: _addPending,
  );

  Future<SelectionOption<String>?> _addPending(BuildContext context) async {
    final name = await showPendingPlaylistNameDialog(
      context,
      initialName: nextDefaultName(
        l10n.playlistDefaultName,
        l10n.plAddDefaultNameNumbered,
        [..._userNames, ...pendingNames.values],
      ),
    );
    if (name == null) return null;
    final key = pendingKey(++_typed);
    pendingNames[key] = name;
    return SelectionOption<String>(
      value: key,
      leading: KCover(
        image: null,
        size: _tile,
        placeholderSeed: key,
        placeholderIcon: KIcons.playlists,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: KSpace.x2),
          ProBadge(label: l10n.playlistPickerNewBadge),
        ],
      ),
      subtitle: Text(l10n.playlistPickerNewHint),
      filterText: name,
    );
  }

  static const double _tile = 44;

  SelectionOption<String> _option(PlaylistRow row) {
    final s = row.summary;
    final name = playlistDisplayName(l10n, s);
    final hint = switch (rowHint(row, _distinct)) {
      NoHint() => '',
      HasThisHint() => ' · ${l10n.playlistPickerHasThis}',
      HasSomeHint(:final has, :final of) =>
        ' · ${l10n.playlistPickerHasSome(has, of)}',
    };
    return SelectionOption<String>(
      value: s.uid,
      leading: PlaylistCover(
        uid: s.uid,
        autoCoverKeys: s.autoCoverKeys,
        dimension: _tile,
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${l10n.playlistTrackCount(s.trackCount)}$hint',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      filterText: name,
      hint: row.favorites ? l10n.playlistPickerFavoritesHint : null,
    );
  }
}
