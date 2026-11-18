import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../state/browse/song_list_providers.dart';
import '../../state/playlists/playlist_providers.dart';
import 'add_to_playlist_confirm.dart';
import 'add_to_playlist_message.dart';
import 'add_to_playlist_model.dart';
import 'add_to_playlist_options.dart';

final _log = Logger('library.add_to_playlist');

/// Longest wait for any read or the write of the flow, so one stuck query
/// cannot leave the "add to playlist" action dead for the whole session.
const addToPlaylistLimit = Duration(seconds: 10);

// Reset in `finally`. It would stay set only if the root navigator were
// disposed with the picker open (app teardown): do not add a timer for that.
bool _running = false;

/// Forgets a flow in progress. For tests that end with the picker open.
@visibleForTesting
void resetAddToPlaylistGuard() => _running = false;

/// Opens the "add to playlist" picker for [request], writes on Thêm and shows
/// the result toast. Ignored while another one is open.
Future<void> showAddToPlaylist(
  BuildContext context,
  AddToPlaylistRequest request,
) => runAddToPlaylist(context, request);

/// [showAddToPlaylist] with a shorter [limit] for tests.
@visibleForTesting
Future<void> runAddToPlaylist(
  BuildContext context,
  AddToPlaylistRequest request, {
  Duration? limit,
}) async {
  if (request.tracks.isEmpty || _running) return;
  _running = true;
  try {
    await _flow(context, request, limit ?? addToPlaylistLimit);
  } finally {
    _running = false;
  }
}

Future<void> _flow(
  BuildContext context,
  AddToPlaylistRequest request,
  Duration limit,
) async {
  // Everything the flow needs after an await is taken now: the page that
  // asked (a menu, the queue sheet) may be gone by then. The messenger and
  // the dialog context belong to the root navigator, so the toast is not
  // trapped in a panel's own Scaffold.
  final navigator = Navigator.of(context, rootNavigator: true);
  final root = navigator.overlay?.context ?? navigator.context;
  final messenger = ScaffoldMessenger.of(navigator.context);
  final container = ProviderScope.containerOf(context, listen: false);
  final store = container.read(playlistStoreProvider);
  final l10n = AppLocalizations.of(context);
  final loadRows = container.read(trackRowLoaderProvider);

  final AddToPlaylistPickerContent content;
  try {
    // Read on every open: a count kept from an earlier open would be stale.
    final summaries = await store.watchSummaries().timeout(limit).first;
    final counts = await store.countExisting(request.tracks).timeout(limit);
    content = AddToPlaylistPickerContent(
      l10n: l10n,
      request: request,
      summaries: summaries,
      counts: counts,
    );
  } on Object catch (e, s) {
    _log.warning('loading playlists failed', e, s);
    showAppSnackBarOn(
      messenger,
      e is TimeoutException ? l10n.plAddTimedOut : l10n.playlistAddFailed,
    );
    return;
  }

  // The root navigator's context outlives the page that asked.
  if (!root.mounted) return;
  final step = AddConfirmStep(
    store: store,
    loadRows: loadRows,
    messenger: messenger,
    dialogContext: root,
    l10n: l10n,
    request: request,
    content: content,
    limit: limit,
  );
  final Set<String>? selected;
  try {
    selected = await showMultiSelectionPicker<String>(
      root,
      title: content.title,
      subtitle: content.subtitle,
      pinned: content.pinned,
      options: content.options,
      leadingAction: content.leadingAction,
      filterHint: content.filterHint,
      footerNote: content.footerNote,
      cancelLabel: content.cancelLabel,
      confirmLabel: content.confirmLabel,
      canConfirm: content.canConfirm,
      confirm: step.call,
      // `step` bounds each read and the write itself; a timeout here would
      // cut off the user's answer to the question.
      confirmTimeout: null,
    );
  } on Object catch (e, s) {
    _log.warning('add to playlist picker failed', e, s);
    showAppSnackBarOn(messenger, l10n.playlistAddFailed);
    return;
  }
  final outcome = step.outcome;
  if (selected == null || outcome == null) return;
  final summary = summarize(
    outcome.result,
    dropped: outcome.dropped,
    namesByUid: content.namesByUid,
    newNames: outcome.newNames,
  );
  showAppSnackBarOn(messenger, addToPlaylistMessage(l10n, summary));
}
