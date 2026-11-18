import 'dart:async';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../state/browse/song_list_providers.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_store.dart';
import 'add_to_playlist_model.dart';
import 'add_to_playlist_options.dart';
import 'already_in_playlist_dialog.dart';

final _log = Logger('library.add_to_playlist');

/// What a confirmed add wrote, and how many songs were left out because they
/// left the library.
typedef AddOutcome = ({
  AddToPlaylistsResult result,
  int dropped,
  List<String> newNames,
});

class _WriteTimedOut implements Exception {
  const _WriteTimedOut();
}

/// The `confirm` step of the "add to playlist" picker: re-checks the ticked
/// playlists and the songs, asks about songs already held, then writes. It
/// runs while the picker is still open, so a failure keeps the picker and its
/// ticks. Every read and the write wait at most [limit]; only the answer to
/// the question waits for the user.
class AddConfirmStep {
  AddConfirmStep({
    required this.store,
    required this.loadRows,
    required this.messenger,
    required this.dialogContext,
    required this.l10n,
    required this.request,
    required this.content,
    required this.limit,
  });

  final PlaylistStore store;

  /// Reads the rows of the batch songs that still exist, whatever their
  /// status (a missing or remote song may be added to a playlist).
  final TrackRowLoader loadRows;
  final ScaffoldMessengerState messenger;

  /// A context that outlives the page that asked (the root navigator's).
  final BuildContext dialogContext;
  final AppLocalizations l10n;
  final AddToPlaylistRequest request;
  final AddToPlaylistPickerContent content;
  final Duration limit;

  /// Set when the write went through (or may have: then it stays null).
  AddOutcome? outcome;

  void _toast(String message) => showAppSnackBarOn(messenger, message);

  /// A message while the picker is open: a toast would sit under the sheet,
  /// so it shows in the picker's footer.
  void _fail(String message, Set<String> selected) =>
      content.showError(message, selected);

  Future<T> _bounded<T>(Future<T> read) => read.timeout(limit);

  /// Resolves to true when the picker may close.
  Future<bool> call(Set<String> selected) async {
    content.clearError();
    try {
      return await _run(selected);
    } on TimeoutException catch (e, s) {
      _log.warning('reading before the add took too long', e, s);
      _fail(l10n.plAddTimedOut, selected);
    } on Object catch (e, s) {
      _log.warning('checking before the add failed', e, s);
      _fail(l10n.playlistAddFailed, selected);
    }
    return false;
  }

  Future<bool> _run(Set<String> selected) async {
    final fresh = await store.watchSummaries().timeout(limit).first;
    final liveUids = {
      fresh.favorites.uid,
      for (final p in fresh.playlists) p.uid,
    };
    final live = liveTicked(selected, liveUids);
    final gone = [
      for (final k in selected)
        if (!isPendingKey(k) && !liveUids.contains(k)) k,
    ];
    content.knownGone.addAll(gone);
    final plan = buildPlan(
      selected: selected,
      liveUids: liveUids,
      pendingNames: content.pendingNames,
    );
    if (plan == null) {
      _fail(l10n.playlistAddedGone(gone.length), selected);
      return false;
    }

    var absent = await _readAbsent();
    var tracks = _present(absent);
    if (tracks.isEmpty) {
      _fail(l10n.plAddSongsGone, selected);
      return false;
    }

    final counts = await _bounded(store.countExisting(tracks));
    final held = affected(live, counts, content.namesByUid);
    // The answer belongs to this attempt only.
    var policy = DuplicatePolicy.skipExisting;
    if (held.isNotEmpty) {
      // The root navigator's context outlives the page that asked.
      if (!dialogContext.mounted) return false;
      final choice = await showAlreadyInPlaylistDialog(
        dialogContext,
        affected: held,
      );
      if (choice == null) return false;
      policy = choice;
    }

    AddToPlaylistsResult result;
    try {
      try {
        result = await _write(plan, tracks, policy);
      } on ArgumentError catch (e, s) {
        // A song was removed after it was read: filter again and retry once.
        _log.info('a song vanished before the write, retrying', e, s);
        absent = {...absent, ...await _readAbsent()}.toList();
        tracks = _present(absent);
        if (tracks.isEmpty) {
          _fail(l10n.plAddSongsGone, selected);
          return false;
        }
        result = await _write(plan, tracks, policy);
      }
    } on _WriteTimedOut {
      // The first write and the retry end here alike: it may still commit.
      _toast(l10n.plAddNotConfirmed);
      return true;
    }
    outcome = (
      result: gone.isEmpty
          ? result
          : AddToPlaylistsResult(
              outcomes: result.outcomes,
              goneUids: [...result.goneUids, ...gone],
              addedTrackCount: result.addedTrackCount,
              skippedTrackCount: result.skippedTrackCount,
            ),
      dropped: absent.toSet().length,
      newNames: plan.newNames,
    );
    return true;
  }

  /// Batch songs with no row at all.
  Future<List<TrackId>> _readAbsent() async {
    final found = {
      for (final info in await _bounded(loadRows(request.tracks))) info.id,
    };
    return [
      for (final t in request.tracks.toSet())
        if (!found.contains(t)) t,
    ];
  }

  List<TrackId> _present(List<TrackId> absent) {
    final out = absent.toSet();
    return [
      for (final t in request.tracks)
        if (!out.contains(t)) t,
    ];
  }

  /// One write. drift cannot cancel a transaction, so a write that timed out
  /// may still commit: it is logged when it ends, and the caller reports
  /// "not confirmed" and closes the picker so it is not pressed twice.
  Future<AddToPlaylistsResult> _write(
    AddPlan plan,
    List<TrackId> tracks,
    DuplicatePolicy policy,
  ) {
    final write = store.addToPlaylists(
      tracks: tracks,
      playlistUids: plan.playlistUids,
      newPlaylistNames: plan.newNames,
      policy: policy,
    );
    return write.timeout(
      limit,
      onTimeout: () {
        unawaited(
          write.then(
            (r) => _log.warning(
              'add finished after the limit: ${r.outcomes.length} targets',
            ),
            onError: (Object e, StackTrace s) =>
                _log.warning('add failed after the limit', e, s),
          ),
        );
        throw const _WriteTimedOut();
      },
    );
  }
}
