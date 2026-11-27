import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/ui/menus/open_menu.dart';
import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';
import '../../playback/state/playback_providers.dart';
import '../state/chat_providers.dart';

/// What a song row of an answer does when the user acts on it. Behind an
/// interface so the row's tests do not need a player or a database.
abstract interface class ChatTrackActions {
  /// Plays [id] now: a user action through the normal playback API, not a
  /// tool call of the assistant.
  Future<void> play(TrackId id);

  /// Opens the song menu of [info].
  Future<void> openMenu(
    BuildContext context,
    TrackInfo info, {
    required bool viaKeyboard,
  });
}

final chatTrackActionsProvider = Provider<ChatTrackActions>(
  _LibraryTrackActions.new,
);

class _LibraryTrackActions implements ChatTrackActions {
  _LibraryTrackActions(this._ref);

  final Ref _ref;

  @override
  Future<void> play(TrackId id) =>
      _ref.read(playerControllerProvider).playTracks(
        [id],
        context: PlayContext(
          PlayContextKind.queue,
          label: _ref.read(aiPlayContextLabelProvider),
        ),
      );

  @override
  Future<void> openMenu(
    BuildContext context,
    TrackInfo info, {
    required bool viaKeyboard,
  }) => openSongMenu(context, info, viaKeyboard: viaKeyboard);
}
