import 'dart:convert';

import '../settings/tool_groups.dart';
import 'ai_tool.dart';
import 'model_text.dart';
import 'tool_args.dart';
import 'tool_env.dart';
import 'write_tool_base.dart';

/// Longest playlist name the assistant may write, in characters.
const int playlistNameMax = 100;

class CreatePlaylistTool extends WriteTool {
  const CreatePlaylistTool();

  @override
  String get name => 'create_playlist';
  @override
  String get description =>
      'Creates a new playlist with the given name and songs. Returns its id.';
  @override
  AiToolGroup get group => AiToolGroup.playlistCreate;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'name': {'type': 'string', 'description': 'Name of the playlist.'},
      'trackIds': trackIdsProperty('Song ids to put in it, in order.'),
    },
    required: const ['name', 'trackIds'],
  );

  @override
  Future<WritePlan> plan(Map<String, Object?> args, ToolEnv env) async {
    final name = sanitizeModelText(
      args.string('name')!,
      maxRunes: playlistNameMax,
    );
    if (name.isEmpty) {
      return const WritePlan.refuse('the playlist name is empty');
    }
    final r = await resolveTracks(env, args.trackIds, allowEmpty: true);
    final t = r.tracks;
    if (t.refusal != null) {
      return WritePlan.refuse(t.refusal!, limitReached: r.limit);
    }
    if (t.visible.isEmpty && args.trackIds.isNotEmpty) {
      return WritePlan.refuse(
        'none of the ids is a song in the library: ${t.absent.join(', ')}',
      );
    }
    final snaps = [for (final v in t.visible) snapshotOf(v)];
    return WritePlan.ready(ToolPreview(summary: name, tracks: snaps), () async {
      final made = await env.playlistsWrite.create(name, [
        for (final v in t.visible) v.id,
      ]);
      return ToolOutcome.ok(
        jsonEncode({
          'playlistId': made.id,
          'name': name,
          'tracks': made.count,
          if (t.absent.isNotEmpty) 'notFound': t.absent,
        }),
        done: ToolDone(added: snaps, absent: t.absent),
      );
    });
  }
}

class AddToPlaylistTool extends WriteTool {
  const AddToPlaylistTool();

  @override
  String get name => 'add_to_playlist';
  @override
  String get description =>
      'Adds songs to a playlist. playlistId comes from list_playlists '
      '(0 is Favorites). Songs the playlist already holds are skipped.';
  @override
  AiToolGroup get group => AiToolGroup.playlistEdit;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'playlistId': {
        'type': 'integer',
        'description': 'Playlist id from list_playlists (0 is Favorites).',
      },
      'trackIds': trackIdsProperty('Song ids to add.'),
    },
    required: const ['playlistId', 'trackIds'],
  );

  @override
  Future<WritePlan> plan(Map<String, Object?> args, ToolEnv env) async {
    final id = args['playlistId'] as int;
    final lists = await env.playlists.list();
    final target = lists.where((p) => p.id == id).firstOrNull;
    if (target == null) return WritePlan.refuse('playlist $id not found');
    final r = await resolveTracks(env, args.trackIds);
    final t = r.tracks;
    if (t.refusal != null) {
      return WritePlan.refuse(t.refusal!, limitReached: r.limit);
    }
    final byId = {for (final v in t.visible) v.id: v};
    return WritePlan.ready(
      ToolPreview(
        summary: sanitizeModelText(target.name, maxRunes: playlistNameMax),
        tracks: [for (final v in t.visible) snapshotOf(v)],
      ),
      () async {
        final res = await env.playlistsWrite.add(id, [
          for (final v in t.visible) v.id,
        ]);
        if (res == null) return ToolOutcome.error('playlist $id not found');
        final added = [
          for (final tid in res.addedTrackIds)
            if (byId[tid] != null) snapshotOf(byId[tid]!),
        ];
        return ToolOutcome.ok(
          jsonEncode({
            'playlistId': id,
            'added': added.length,
            'alreadyThere': res.skipped,
            if (t.absent.isNotEmpty) 'notFound': t.absent,
          }),
          done: ToolDone(added: added, absent: t.absent),
        );
      },
    );
  }
}

class RemoveFromPlaylistTool extends WriteTool {
  const RemoveFromPlaylistTool();

  @override
  String get name => 'remove_from_playlist';
  @override
  String get description =>
      'Removes entries from a playlist. entryIds are the entry ids that '
      'get_playlist_tracks returns (not song ids).';
  @override
  AiToolGroup get group => AiToolGroup.playlistEdit;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'playlistId': {
        'type': 'integer',
        'description': 'Playlist id from list_playlists (0 is Favorites).',
      },
      'entryIds': {
        'type': 'array',
        'items': {'type': 'integer'},
        'maxItems': writeIdsMax,
        'description': 'Entry ids from get_playlist_tracks.',
      },
    },
    required: const ['playlistId', 'entryIds'],
  );

  @override
  Future<WritePlan> plan(Map<String, Object?> args, ToolEnv env) async {
    final id = args['playlistId'] as int;
    final ids = args.intList('entryIds').toSet().toList();
    if (ids.isEmpty) return const WritePlan.refuse('entryIds is empty');
    final usage = await env.turnUsage();
    if (!usage.canRemove(ids.length)) {
      return WritePlan.refuse(removeLimitText(usage), limitReached: true);
    }
    final current = await env.playlists.entries(id);
    if (current == null) return WritePlan.refuse('playlist $id not found');
    final wanted = ids.toSet();
    final shown = [
      for (final e in current.entries)
        if (wanted.contains(e.entryId)) snapshotOf(e.track),
    ];
    return WritePlan.ready(
      ToolPreview(
        summary: sanitizeModelText(current.name, maxRunes: playlistNameMax),
        tracks: shown,
      ),
      () async {
        final res = await env.playlistsWrite.removeEntries(id, ids);
        if (res == null) return ToolOutcome.error('playlist $id not found');
        final titles = await env.library.visibleOf([
          for (final e in res.removed) e.trackId,
        ]);
        final byId = {for (final v in titles.visible) v.id: v};
        final snaps = [
          for (final e in res.removed)
            byId[e.trackId] == null
                ? unknownSnapshot(e.trackId)
                : snapshotOf(byId[e.trackId]!),
        ];
        final gone = {for (final e in res.removed) e.entryId};
        return ToolOutcome.ok(
          jsonEncode({
            'playlistId': id,
            'removed': res.removed.length,
            'notInPlaylist': [
              for (final e in ids)
                if (!gone.contains(e)) e,
            ],
          }),
          done: ToolDone(removed: snaps),
        );
      },
    );
  }
}
