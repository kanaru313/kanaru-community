import 'package:flutter/widgets.dart' show BuildContext;

import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/music_folder.dart';
import '../../domain/playlists/playlist_models.dart';

/// What a row does once chosen. Executed by the action runner, never by the
/// builder, so a model is plain data.
sealed class MenuAction {
  const MenuAction();

  /// Opens a library page.
  const factory MenuAction.go(String location) = GoAction;

  /// Favourites or unfavourites [ids].
  const factory MenuAction.favorite(List<TrackId> ids, {required bool on}) =
      FavoriteAction;

  /// Excludes [folderKey] of [folder] from the library.
  const factory MenuAction.exclude(
    MusicFolder folder,
    String folderKey, {
    required String displayPath,
  }) = ExcludeAction;

  /// Puts [text] on the clipboard.
  const factory MenuAction.copy(String text) = CopyAction;

  /// Shows the file or folder at [path] in the file manager.
  const factory MenuAction.reveal(String path) = RevealAction;

  /// Adds [id] to the selection, or removes it.
  const factory MenuAction.select(TrackId id, {required bool on}) =
      SelectTrackAction;

  /// Replaces the queue with [ids].
  const factory MenuAction.play(
    List<TrackId> ids, {
    required bool shuffle,
    required PlayContext context,
  }) = PlayAction;

  /// Opens the add-to-playlist picker for [request].
  const factory MenuAction.addToPlaylist(AddToPlaylistRequest request) =
      AddToPlaylistAction;

  /// Runs [run] with the root navigator's context once the menu has closed
  /// (a dialog, a picker, a page of the caller's own). A failure is logged
  /// and shown as a toast by the runner.
  const factory MenuAction.run(
    Future<void> Function(BuildContext context) run,
  ) = RunAction;
}

class GoAction extends MenuAction {
  const GoAction(this.location);
  final String location;

  @override
  bool operator ==(Object other) =>
      other is GoAction && other.location == location;

  @override
  int get hashCode => location.hashCode;
}

class FavoriteAction extends MenuAction {
  const FavoriteAction(this.ids, {required this.on});
  final List<TrackId> ids;
  final bool on;

  @override
  bool operator ==(Object other) =>
      other is FavoriteAction && other.on == on && _same(other.ids, ids);

  @override
  int get hashCode => Object.hash(on, Object.hashAll(ids));
}

class ExcludeAction extends MenuAction {
  const ExcludeAction(this.folder, this.folderKey, {required this.displayPath});
  final MusicFolder folder;
  final String folderKey;
  final String displayPath;

  @override
  bool operator ==(Object other) =>
      other is ExcludeAction &&
      other.folder == folder &&
      other.folderKey == folderKey &&
      other.displayPath == displayPath;

  @override
  int get hashCode => Object.hash(folder, folderKey, displayPath);
}

class CopyAction extends MenuAction {
  const CopyAction(this.text);
  final String text;

  @override
  bool operator ==(Object other) => other is CopyAction && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

class RevealAction extends MenuAction {
  const RevealAction(this.path);
  final String path;

  @override
  bool operator ==(Object other) => other is RevealAction && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

class SelectTrackAction extends MenuAction {
  const SelectTrackAction(this.id, {required this.on});
  final TrackId id;
  final bool on;

  @override
  bool operator ==(Object other) =>
      other is SelectTrackAction && other.id == id && other.on == on;

  @override
  int get hashCode => Object.hash(id, on);
}

class PlayAction extends MenuAction {
  const PlayAction(this.ids, {required this.shuffle, required this.context});
  final List<TrackId> ids;
  final bool shuffle;
  final PlayContext context;

  @override
  bool operator ==(Object other) =>
      other is PlayAction &&
      other.shuffle == shuffle &&
      other.context == context &&
      _same(other.ids, ids);

  @override
  int get hashCode => Object.hash(shuffle, context, Object.hashAll(ids));
}

class AddToPlaylistAction extends MenuAction {
  const AddToPlaylistAction(this.request);
  final AddToPlaylistRequest request;

  // The request compares its tracks in order, its label and the excluded
  // playlist.
  @override
  bool operator ==(Object other) =>
      other is AddToPlaylistAction && other.request == request;

  @override
  int get hashCode => request.hashCode;
}

/// An action the caller supplies as code. Compared by identity of [run].
class RunAction extends MenuAction {
  const RunAction(this.run);
  final Future<void> Function(BuildContext context) run;

  @override
  bool operator ==(Object other) => other is RunAction && other.run == run;

  @override
  int get hashCode => run.hashCode;
}

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
