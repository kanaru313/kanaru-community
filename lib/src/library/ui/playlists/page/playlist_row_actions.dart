import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import 'playlist_entry_menu.dart';
import 'playlist_entry_removal.dart';
import 'playlist_page_actions.dart';
import 'playlist_rows_sliver.dart';

/// What the rows of playlist [uid]'s page do, wired to the page's own
/// [onStep] (menu Up / Down by entry uid and delta) and drag callbacks.
/// [rowCount] is read when a menu is built: the last row cannot go down.
PlaylistRowActions playlistRowActions(
  BuildContext context,
  AppLocalizations l10n, {
  required String uid,
  required bool isFavorites,
  required bool canStep,
  required int Function() rowCount,
  required void Function(String entryUid, int delta) onStep,
  required PlaylistEntryRemoval removal,
  required void Function(int index) onReorderStart,
  required void Function(int oldIndex, int newIndex) onReorderItem,
}) {
  Future<void> remove(BuildContext ctx, PlaylistEntryView e) =>
      removeEntryOnPage(ctx, uid, e);
  return PlaylistRowActions(
    menuExtras: (entry, i) => playlistEntryMenuGroup(
      l10n,
      isFavorites: isFavorites,
      canStep: canStep,
      isFirst: i == 0,
      isLast: i == rowCount() - 1,
      onStep: (delta) => onStep(entry.uid, delta),
      onRemove: (ctx) => remove(ctx, entry),
    ),
    missingMenu: (entry, {required viaKeyboard}) => openMissingEntryMenu(
      context,
      entry: entry,
      isFavorites: isFavorites,
      onRemove: (ctx) => remove(ctx, entry),
      viaKeyboard: viaKeyboard,
    ),
    removeMissing: (entry) => unawaited(remove(context, entry)),
    removal: removal,
    onReorderStart: onReorderStart,
    onReorderItem: onReorderItem,
  );
}
