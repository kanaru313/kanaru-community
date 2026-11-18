import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/playlists/playlist_ids.dart';
import '../../state/custom_cover_providers.dart';
import '../../state/playlists/playlist_page_controller.dart';
import '../detail/detail_header.dart';
import '../detail/detail_tint.dart';
import '../library_locations.dart';
import '../playlist_common/playlist_labels.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'page/playlist_edit_mode.dart';
import 'page/playlist_edit_toggle.dart';
import 'page/playlist_hero.dart';
import 'page/playlist_page_states.dart';
import 'page/playlist_songs_slivers.dart';

/// One playlist, or Favorites (uid `favorites`): the frame with the cover
/// tint, the hero (a left column on a wide page) and the songs.
///
/// Favorites is also a sidebar item: on desktop its header stays a root
/// header (no back button) in every state; on mobile every playlist page is
/// a child of the tab and has one.
class PlaylistPage extends ConsumerStatefulWidget {
  const PlaylistPage({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  /// Edit mode lives and dies with this page.
  final PlaylistEditMode _edit = PlaylistEditMode();

  /// Owns Esc while editing. Focus sits in the page then, so the desktop
  /// shell's own Esc (history back) is not asked and the page is not left.
  final FocusNode _focus = FocusNode(
    debugLabel: 'PlaylistPage',
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    _edit.addListener(_onEditChanged);
  }

  @override
  void dispose() {
    _edit.removeListener(_onEditChanged);
    _edit.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Entering takes focus unless something inside the page has it already (a
  /// keyboard user's toggle); leaving gives back what the page took.
  void _onEditChanged() {
    if (_edit.editing) {
      if (!_focus.hasFocus) _focus.requestFocus();
      // Focus that sat on a node the rebuild removes (the filter field, a
      // row) falls back to the route once the frame is done (the focus
      // manager settles in a microtask): take it again then.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scheduleMicrotask(() {
          if (mounted && _edit.editing && !_focus.hasFocus) {
            _focus.requestFocus();
          }
        });
      });
    } else if (_focus.hasPrimaryFocus) {
      _focus.unfocus();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_edit.editing ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    // A drag in progress ends first; the key is still the page's.
    if (!_edit.dragging) _edit.exit();
    return KeyEventResult.handled;
  }

  String get uid => widget.uid;

  @override
  Widget build(BuildContext context) {
    final isFavorites = uid == PlaylistUids.favorites;
    final showBack =
        !(isFavorites && FormFactor.of(context) == FormFactor.desktop);
    final async = ref.watch(playlistPageProvider(uid).select((s) => s.detail));
    final detail = async.value;
    if (detail == null) {
      return async.hasValue
          ? PlaylistNotFound(showBack: showBack)
          : PlaylistPending(showBack: showBack, failed: async.hasError);
    }
    final summary = detail.summary;
    final tint = isFavorites
        ? null
        : watchDetailTint(ref, (
            kind: CustomCoverKind.playlist,
            itemKey: uid,
          ), summary.autoCoverKeys.firstOrNull);
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: ListenableBuilder(
        listenable: _edit,
        builder: (context, _) => DetailFrame(
          title: playlistDisplayName(AppLocalizations.of(context), summary),
          fallback: LibraryLocations.playlists,
          tint: tint,
          showBack: showBack,
          // Only a playlist with entries has something to edit.
          actions: [
            if (detail.entries.isNotEmpty || _edit.editing)
              PlaylistEditToggle(
                editing: _edit.editing,
                onPressed: _edit.dragging ? null : _edit.toggle,
              ),
          ],
          child: PlaylistSongsHost(
            detail: detail,
            edit: _edit,
            builder: (context, slivers, serving, play) => KDetailLayout(
              header: PlaylistHero(
                detail: detail,
                serving: serving,
                onPlay: play,
                editing: _edit.editing,
              ),
              slivers: slivers,
            ),
          ),
        ),
      ),
    );
  }
}
