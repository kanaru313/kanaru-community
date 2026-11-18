import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_store.dart';
import '../../state/playlists/playlist_page_controller.dart';
import '../../state/playlists/playlist_providers.dart';

final _log = Logger('library.playlists');

/// Holds the one playlist removal whose "Undo" toast is still open. A removal
/// leaves tombstones; closing the toast untouched commits them (deletes them
/// for good), and so does the next removal and the end of the container.
///
/// Committing is idempotent per removal, so the three triggers can overlap.
/// A failed commit only logs: the tombstones are purged later.
class PlaylistRemovalHolder {
  PlaylistRemovalHolder(this._store);

  final PlaylistStore _store;
  PlaylistRemoval? _pending;

  /// Makes [removal] the pending one; the previous pending removal is
  /// committed first (a new toast replaced its toast).
  void hold(PlaylistRemoval removal) {
    final previous = _pending;
    _pending = removal;
    if (previous != null && previous != removal) unawaited(_commit(previous));
  }

  /// Commits [removal] unless it is no longer pending (undone, or committed
  /// already).
  Future<void> commit(PlaylistRemoval removal) async {
    if (_pending != removal) return;
    _pending = null;
    await _commit(removal);
  }

  /// Commits whatever is pending (the container is going away).
  Future<void> commitPending() async {
    final pending = _pending;
    if (pending != null) await commit(pending);
  }

  /// Stops [removal] from being committed because the user undoes it.
  void cancel(PlaylistRemoval removal) {
    if (_pending == removal) _pending = null;
  }

  Future<void> _commit(PlaylistRemoval removal) async {
    try {
      await _store.commitRemoval(removal);
    } on Object catch (error, stack) {
      _log.warning('Committing a playlist removal failed', error, stack);
    }
  }
}

/// One holder per app: at most one removal waits for its toast.
final playlistRemovalHolderProvider = Provider<PlaylistRemovalHolder>((ref) {
  final holder = PlaylistRemovalHolder(ref.watch(playlistStoreProvider));
  ref.onDispose(() => unawaited(holder.commitPending()));
  return holder;
});

/// Toast "[message]  Undo" for [removal], on the root navigator's
/// [rootContext] (not the page that asked, which may close before the toast
/// does). Undo brings the entries back; closing the toast any other way
/// commits the removal.
void showRemovalToast(
  BuildContext rootContext,
  ProviderContainer container,
  PlaylistRemoval removal,
  String message,
) {
  final l10n = AppLocalizations.of(rootContext);
  final messenger = ScaffoldMessenger.of(rootContext);
  final holder = container.read(playlistRemovalHolderProvider);
  holder.hold(removal);
  showAppSnackBarOn(
    messenger,
    message,
    actionLabel: l10n.libraryMenuUndo,
    onAction: () => unawaited(_undo(container, messenger, l10n, removal)),
    onClosedWithoutAction: () => unawaited(holder.commit(removal)),
  );
}

/// A removal that failed: logs it ([what] names the action and playlist) and
/// says so once on [messenger]. A write cancelled because one queued before it
/// failed is silent (that failure said it already).
void reportRemovalFailure(
  Object error,
  StackTrace stack,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n, {
  required String what,
}) {
  if (error is PlaylistWriteFailure && error.cancelled) return;
  _log.warning('$what failed', error, stack);
  if (messenger.mounted) showAppSnackBarOn(messenger, l10n.playlistSaveFailed);
}

Future<void> _undo(
  ProviderContainer container,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  PlaylistRemoval removal,
) async {
  container.read(playlistRemovalHolderProvider).cancel(removal);
  var revived = 0;
  try {
    final page = playlistPageProvider(removal.playlistUid);
    if (container.read(page.exists)) {
      // Through the open page's write queue, behind the writes it already
      // holds. The controller finishes its queue even if the page closes
      // meanwhile, so no listener is needed to keep it alive.
      revived = await container.read(page.notifier).undo(removal);
    } else {
      revived = await container
          .read(playlistStoreProvider)
          .undoRemoval(removal);
    }
  } on Object catch (error, stack) {
    _log.warning('Undoing a playlist removal failed', error, stack);
  }
  if (revived == 0 && messenger.mounted) {
    showAppSnackBarOn(messenger, l10n.libraryMenuUndoFailed);
  }
}
