import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../database/state/database_providers.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../../playback/domain/playback_commands.dart';
import '../../../playback/state/playback_providers.dart';
import '../../data/browse/song_ids_query.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';

final _log = Logger('library.play');

/// Plays [ids] from [index] (a tap on a row). The queue is the list as shown.
Future<void> playFrom(
  WidgetRef ref,
  BuildContext context,
  List<TrackId> ids,
  int index,
  PlayContext playContext,
) => _run(
  ref,
  context,
  (commands) => playIds(commands, ids, playContext, startIndex: index),
  isEmpty: ids.isEmpty,
);

/// Plays [ids] in order from the first.
Future<void> playAll(
  WidgetRef ref,
  BuildContext context,
  List<TrackId> ids,
  PlayContext playContext,
) => playFrom(ref, context, ids, 0, playContext);

/// Plays [ids] shuffled, starting at a random one.
Future<void> shuffleAll(
  WidgetRef ref,
  BuildContext context,
  List<TrackId> ids,
  PlayContext playContext,
) => _run(
  ref,
  context,
  (commands) => playIds(commands, ids, playContext, shuffle: true),
  isEmpty: ids.isEmpty,
);

/// Reads the ids of a scope in the order of a list's default sort; tests
/// replace it to hold a read back.
typedef ScopeIdsReader = Future<List<TrackId>> Function(
  SongScope scope,
  SortSpec sort,
);

final scopeIdsReaderProvider = Provider<ScopeIdsReader>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (scope, sort) => songIds(db, scope, sort, '');
});

/// Number of the newest library play request. Every way to start playback
/// from the library (a tap, ▶, a menu's Play, the selection panel) takes a
/// number first; a scope read that finishes after a newer request started is
/// dropped, so a slow ▶ cannot replace the queue the user started afterwards.
int _newestPlay = 0;

/// Starts a library play request; the returned number is its identity.
int beginPlayRequest() => ++_newestPlay;

/// Whether [request] is still the newest one.
bool isNewestPlay(int request) => request == _newestPlay;

/// The one place that turns ids into a `playTracks` call: [shuffle] starts at
/// a random id, otherwise at [startIndex].
Future<void> playIds(
  PlaybackCommands commands,
  List<TrackId> ids,
  PlayContext context, {
  bool shuffle = false,
  int startIndex = 0,
}) => commands.playTracks(
  ids,
  startIndex: shuffle ? Random().nextInt(ids.length) : startIndex,
  shuffle: shuffle,
  context: context,
);

/// Reads the tracks of [scope] in [sort] (default: the default order of
/// [list]) at the moment
/// of the call (a ▶ button on a tile that does not hold the ids), then plays
/// them. The tile may leave the tree during the read (a scan refresh, a
/// scroll): everything needed is taken before the read, so the play still
/// happens.
Future<void> playScope(
  WidgetRef ref,
  BuildContext context,
  SongScope scope,
  BrowseList list,
  PlayContext playContext, {
  SortSpec? sort,
}) => _playScoped(
  ref,
  context,
  scope,
  list,
  playContext,
  shuffle: false,
  sort: sort,
);

/// Like [playScope], shuffled.
Future<void> shuffleScope(
  WidgetRef ref,
  BuildContext context,
  SongScope scope,
  BrowseList list,
  PlayContext playContext, {
  SortSpec? sort,
}) => _playScoped(
  ref,
  context,
  scope,
  list,
  playContext,
  shuffle: true,
  sort: sort,
);

Future<void> _playScoped(
  WidgetRef ref,
  BuildContext context,
  SongScope scope,
  BrowseList list,
  PlayContext playContext, {
  required bool shuffle,
  SortSpec? sort,
}) async {
  final request = beginPlayRequest();
  final read = ref.read(scopeIdsReaderProvider);
  final commands = ref.read(playbackCommandsProvider);
  final message = AppLocalizations.of(context).libraryPlayFailed;
  // The root navigator outlives the tile, so the failure can still be shown.
  final root = Navigator.of(context, rootNavigator: true).context;
  try {
    final ids = await read(scope, sort ?? defaultSortOf(list));
    if (!isNewestPlay(request)) {
      _log.fine('play request $request dropped: a newer one started');
      return;
    }
    if (ids.isEmpty) return;
    await playIds(commands, ids, playContext, shuffle: shuffle);
  } on Object catch (e, s) {
    _log.warning('playing a scope failed', e, s);
    if (root.mounted) showAppSnackBar(root, message);
  }
}

Future<void> _run(
  WidgetRef ref,
  BuildContext context,
  Future<void> Function(PlaybackCommands commands) action, {
  required bool isEmpty,
}) async {
  if (isEmpty) return;
  beginPlayRequest();
  final commands = ref.read(playbackCommandsProvider);
  final message = AppLocalizations.of(context).libraryPlayFailed;
  try {
    await action(commands);
  } on Object catch (e, s) {
    _log.warning('playback request failed', e, s);
    if (context.mounted) showAppSnackBar(context, message);
  }
}
