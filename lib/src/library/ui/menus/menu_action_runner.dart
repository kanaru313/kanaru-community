import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../../platform/state/file_manager_provider.dart';
import '../../../playback/state/playback_providers.dart';
import '../../state/browse/selection_providers.dart';
import '../../state/favorites_providers.dart';
import '../../state/folder_exclusion_providers.dart';
import '../browse/library_navigation.dart';
import 'menu_model.dart';

final _log = Logger('library.menu');

/// Executes the actions of a menu: playback, favourites, exclusion with
/// undo, copy, reveal, selection and navigation.
///
/// It holds the [ProviderContainer] and a [context] of the root navigator
/// (not the tile the menu was opened from), so a menu chosen after its tile
/// scrolled away or its page closed still works and its toast still shows.
/// Every call is awaited; a failure is logged and shown as a toast, never
/// swallowed.
class MenuActionRunner {
  MenuActionRunner(this._container, this._context);

  final ProviderContainer _container;
  final BuildContext _context;

  AppLocalizations get _l10n => AppLocalizations.of(_context);

  Future<void> run(MenuAction action) async {
    switch (action) {
      case GoAction(:final location):
        // A push: Back returns to the page the menu was opened from. Not
        // awaited, the future completes when that page is popped.
        try {
          unawaited(openLibraryPage<void>(_context, location));
        } on Object catch (e, s) {
          _fail('opening $location', _l10n.libraryMenuLoadFailed, e, s);
        }
      case FavoriteAction(:final ids, :final on):
        await _guard('setting favorites', _l10n.libraryFavoriteFailed, () {
          return _container
              .read(favoritesControllerProvider)
              .setFavorite(ids, on);
        });
      case ExcludeAction(:final folder, :final folderKey, :final displayPath):
        final exclusions = _container.read(folderExclusionsProvider);
        final done = await _guard(
          'excluding $folderKey',
          _l10n.libraryMenuExcludeFailed,
          () => exclusions.exclude(folder, folderKey, displayPath: displayPath),
        );
        if (!done || !_context.mounted) return;
        // The undo holds the service and the key, not the page that is gone.
        showAppSnackBar(
          _context,
          _l10n.libraryMenuExcluded(
            folderKey.isEmpty ? folder.name : folderKey.split('/').last,
          ),
          actionLabel: _l10n.libraryMenuUndo,
          onAction: () => unawaited(
            _guard(
              'undoing the exclusion of $folderKey',
              _l10n.libraryMenuUndoFailed,
              () => exclusions.include(folder, folderKey),
            ),
          ),
        );
      case CopyAction(:final text):
        final done = await _guard(
          'copying a path',
          _l10n.libraryMenuCopyFailed,
          () => Clipboard.setData(ClipboardData(text: text)),
        );
        if (done && _context.mounted) {
          showAppSnackBar(_context, _l10n.libraryMenuPathCopied);
        }
      case RevealAction(:final path):
        final message = _l10n.libraryMenuRevealFailed;
        await _guard('revealing $path', message, () async {
          final result = await _container
              .read(fileManagerProvider)
              .reveal(path);
          result.fold((_) {}, (error) {
            _log.warning('file manager could not show $path: $error');
            if (_context.mounted) showAppSnackBar(_context, message);
          });
        });
      case SelectTrackAction(:final id, :final on):
        final selection = _container.read(librarySelectionProvider.notifier);
        if (on) {
          if (!selection.contains(id)) selection.toggle(id);
        } else {
          selection.remove(id);
        }
      case PlayAction(:final ids, :final shuffle, :final context):
        if (ids.isEmpty) return;
        await _guard('starting playback', _l10n.libraryPlayFailed, () {
          return _container
              .read(playbackCommandsProvider)
              .playTracks(
                ids,
                startIndex: shuffle ? Random().nextInt(ids.length) : 0,
                shuffle: shuffle,
                context: context,
              );
        });
    }
  }

  /// "Play next" button of the menu footer.
  Future<void> playNext(List<TrackId> ids) async {
    if (ids.isEmpty) return;
    final done = await _guard(
      'queueing next',
      _l10n.libraryMenuQueueFailed,
      () {
        return _container.read(playbackCommandsProvider).playNext(ids);
      },
    );
    if (done && _context.mounted) {
      showAppSnackBar(_context, _l10n.libraryMenuPlayingNext);
    }
  }

  /// "Add to queue" button of the menu footer.
  Future<void> enqueue(List<TrackId> ids) async {
    if (ids.isEmpty) return;
    final done = await _guard('queueing', _l10n.libraryMenuQueueFailed, () {
      return _container.read(playbackCommandsProvider).enqueue(ids);
    });
    if (done && _context.mounted) {
      showAppSnackBar(_context, _l10n.libraryMenuQueued);
    }
  }

  /// Runs [body]; a failure is logged and shown as [message]. True when it
  /// finished.
  Future<bool> _guard(
    String what,
    String message,
    Future<void> Function() body,
  ) async {
    try {
      await body();
      return true;
    } on Object catch (e, s) {
      _fail(what, message, e, s);
      return false;
    }
  }

  void _fail(String what, String message, Object e, StackTrace s) {
    _log.warning('$what failed', e, s);
    if (_context.mounted) showAppSnackBar(_context, message);
  }
}
