import 'dart:convert';

import '../settings/tool_groups.dart';
import 'ai_tool.dart';
import 'tool_args.dart';
import 'tool_env.dart';
import 'write_tool_base.dart';

class PlayTracksTool extends WriteTool {
  const PlayTracksTool();

  @override
  String get name => 'play_tracks';
  @override
  String get description =>
      'Replaces the queue with the given songs and starts playing. Use song '
      'ids from search_library or other tools. startIndex is the position '
      'in trackIds of the song to start with (default 0).';
  @override
  AiToolGroup get group => AiToolGroup.playControl;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'trackIds': trackIdsProperty('Song ids, in play order.'),
      'startIndex': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Position in trackIds to start from.',
      },
    },
    required: const ['trackIds'],
  );

  @override
  Future<WritePlan> plan(Map<String, Object?> args, ToolEnv env) async {
    final ids = args.trackIds;
    final start = args.intOr('startIndex', 0);
    if (ids.isNotEmpty && start >= ids.length) {
      return const WritePlan.refuse('startIndex is past the end of trackIds');
    }
    final r = await resolveTracks(env, ids);
    final t = r.tracks;
    if (t.refusal != null) {
      return WritePlan.refuse(t.refusal!, limitReached: r.limit);
    }
    final startAt = t.visible.indexWhere((v) => v.id == ids[start]);
    if (startAt < 0) {
      return const WritePlan.refuse(
        'the song at startIndex is not in the library',
      );
    }
    final snaps = [for (final v in t.visible) snapshotOf(v)];
    return WritePlan.ready(
      ToolPreview(summary: 'play', tracks: snaps),
      () async {
        final replaced = await env.playbackWrite.play(
          [for (final v in t.visible) v.id],
          startIndex: startAt,
          contextLabel: env.playContextLabel,
        );
        return ToolOutcome.ok(
          jsonEncode({
            'playing': snaps.length,
            'startedWith': t.visible[startAt].id,
            if (t.absent.isNotEmpty) 'notFound': t.absent,
          }),
          done: ToolDone(
            added: snaps,
            absent: t.absent,
            replacedQueue: replaced,
          ),
        );
      },
    );
  }
}

class QueueTracksTool extends WriteTool {
  const QueueTracksTool();

  @override
  String get name => 'queue_tracks';
  @override
  String get description =>
      'Adds songs to the queue, right after the current song (position '
      '"next") or at the end ("end", the default). On an empty queue the '
      'songs start playing.';
  @override
  AiToolGroup get group => AiToolGroup.queueEdit;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'trackIds': trackIdsProperty('Song ids, in the order to queue them.'),
      'position': {
        'type': 'string',
        'enum': ['next', 'end'],
        'description': 'next or end (default).',
      },
    },
    required: const ['trackIds'],
  );

  @override
  Future<WritePlan> plan(Map<String, Object?> args, ToolEnv env) async {
    final r = await resolveTracks(env, args.trackIds);
    final t = r.tracks;
    if (t.refusal != null) {
      return WritePlan.refuse(t.refusal!, limitReached: r.limit);
    }
    final next = args.string('position') == 'next';
    final snaps = [for (final v in t.visible) snapshotOf(v)];
    return WritePlan.ready(
      ToolPreview(summary: next ? 'queue next' : 'queue end', tracks: snaps),
      () async {
        final res = await env.playbackWrite.queue([
          for (final v in t.visible) v.id,
        ], next: next);
        return ToolOutcome.ok(
          jsonEncode({
            'queued': snaps.length,
            'position': next ? 'next' : 'end',
            if (res.startedPlayback)
              'note': 'the queue was empty, so playback started',
            if (t.absent.isNotEmpty) 'notFound': t.absent,
          }),
          done: ToolDone(added: snaps, absent: t.absent),
        );
      },
    );
  }
}

class RemoveFromQueueTool extends WriteTool {
  const RemoveFromQueueTool();

  @override
  String get name => 'remove_from_queue';
  @override
  String get description =>
      'Removes entries from the queue. entryIds are the entry ids that '
      'get_queue returns (not song ids).';
  @override
  AiToolGroup get group => AiToolGroup.queueEdit;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'entryIds': {
        'type': 'array',
        'items': {'type': 'integer'},
        'maxItems': writeIdsMax,
        'description': 'Queue entry ids from get_queue.',
      },
    },
    required: const ['entryIds'],
  );

  @override
  Future<WritePlan> plan(Map<String, Object?> args, ToolEnv env) async {
    final ids = args.intList('entryIds').toSet().toList();
    if (ids.isEmpty) return const WritePlan.refuse('entryIds is empty');
    final usage = await env.turnUsage();
    if (!usage.canRemove(ids.length)) {
      return WritePlan.refuse(removeLimitText(usage), limitReached: true);
    }
    // The card shows the entries that are in the queue now.
    final queue = await env.playback.queue();
    final wanted = {for (final i in queue.items) i.entryId: i.trackId};
    final inQueue = [
      for (final id in ids)
        if (wanted.containsKey(id)) wanted[id]!,
    ];
    final shown = await env.library.visibleOf(inQueue);
    final byId = {for (final v in shown.visible) v.id: v};
    final preview = [
      for (final id in inQueue)
        byId[id] == null ? unknownSnapshot(id) : snapshotOf(byId[id]!),
    ];
    return WritePlan.ready(
      ToolPreview(summary: 'remove from queue', tracks: preview),
      () async {
        final removed = await env.playbackWrite.removeEntries(ids);
        final titles = await env.library.visibleOf([
          for (final e in removed) e.trackId,
        ]);
        final titleById = {for (final v in titles.visible) v.id: v};
        final snaps = [
          for (final e in removed)
            titleById[e.trackId] == null
                ? unknownSnapshot(e.trackId)
                : snapshotOf(titleById[e.trackId]!),
        ];
        final gone = {for (final e in removed) e.entryId};
        return ToolOutcome.ok(
          jsonEncode({
            'removed': removed.length,
            'removedEntryIds': [for (final e in removed) e.entryId],
            'notInQueue': [
              for (final id in ids)
                if (!gone.contains(id)) id,
            ],
          }),
          done: ToolDone(removed: snaps),
        );
      },
    );
  }
}
