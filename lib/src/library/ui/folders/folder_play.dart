import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/play_context.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/music_folder.dart';
import '../browse/play_actions.dart';

/// Play context of a folder, shared by the folder page's Play, the folder
/// menu's Play and the row's ▶.
PlayContext folderPlayContext(String sourceUid, String key, String label) =>
    PlayContext(PlayContextKind.folder, ref: '$sourceUid:$key', label: label);

/// The songs a folder's Play takes: the folder with its subfolders (tree
/// view), or only its own songs ([flat], the flat list).
SongScope folderPlayScope(int sourceId, String key, {bool flat = false}) =>
    SongScope.folder(sourceId, key, direct: flat);

/// Plays a folder from its row's ▶: the songs, order (title, the sort every
/// folder page lists in) and context of its page's Play, given the folder's
/// own [name].
Future<void> playFolder(
  WidgetRef ref,
  BuildContext context, {
  required MusicFolder folder,
  required String key,
  required String name,
  bool flat = false,
}) => playScope(
  ref,
  context,
  folderPlayScope(folder.sourceId, key, flat: flat),
  BrowseList.songs,
  folderPlayContext(folder.sourceUid, key, name),
);
