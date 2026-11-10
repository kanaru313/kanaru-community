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
  (commands) =>
      commands.playTracks(ids, startIndex: index, context: playContext),
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
  (commands) => commands.playTracks(
    ids,
    startIndex: Random().nextInt(ids.length),
    shuffle: true,
    context: playContext,
  ),
  isEmpty: ids.isEmpty,
);

/// Reads the tracks of [scope] in the default order of [list] at the moment
/// of the call (a ▶ button on a tile that does not hold the ids), then plays
/// them. Calls [songIds] directly: no provider is read for a one-shot answer.
Future<void> playScope(
  WidgetRef ref,
  BuildContext context,
  SongScope scope,
  BrowseList list,
  PlayContext playContext,
) async {
  final ids = await _readIds(ref, context, scope, list);
  if (ids == null || !context.mounted) return;
  await playAll(ref, context, ids, playContext);
}

/// Like [playScope], shuffled.
Future<void> shuffleScope(
  WidgetRef ref,
  BuildContext context,
  SongScope scope,
  BrowseList list,
  PlayContext playContext,
) async {
  final ids = await _readIds(ref, context, scope, list);
  if (ids == null || !context.mounted) return;
  await shuffleAll(ref, context, ids, playContext);
}

/// The ids of [scope], or null after telling the user the read failed.
Future<List<TrackId>?> _readIds(
  WidgetRef ref,
  BuildContext context,
  SongScope scope,
  BrowseList list,
) async {
  final db = ref.read(appDatabaseProvider);
  final message = AppLocalizations.of(context).libraryPlayFailed;
  try {
    return await songIds(db, scope, defaultSortOf(list), '');
  } on Object catch (e, s) {
    _log.warning('reading the tracks to play failed', e, s);
    if (context.mounted) showAppSnackBar(context, message);
    return null;
  }
}

Future<void> _run(
  WidgetRef ref,
  BuildContext context,
  Future<void> Function(PlaybackCommands commands) action, {
  required bool isEmpty,
}) async {
  if (isEmpty) return;
  final commands = ref.read(playbackCommandsProvider);
  final message = AppLocalizations.of(context).libraryPlayFailed;
  try {
    await action(commands);
  } on Object catch (e, s) {
    _log.warning('playback request failed', e, s);
    if (context.mounted) showAppSnackBar(context, message);
  }
}
