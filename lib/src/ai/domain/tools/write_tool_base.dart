import '../conversation/track_ref_snapshot.dart';
import 'ai_tool.dart';
import 'item_caps.dart';
import 'model_text.dart';
import 'schema_validator.dart';
import 'tool_args.dart';
import 'tool_env.dart';

/// Most ids one write call takes.
const int writeIdsMax = 200;

/// A write that was checked against the library as it is now: the card to
/// show and the action to run, or the reason it cannot run.
class WritePlan {
  const WritePlan.ready(
    ToolPreview this.preview,
    Future<ToolOutcome> Function() this.execute,
  ) : refusal = null,
      limitReached = false;
  const WritePlan.refuse(String this.refusal, {this.limitReached = false})
    : preview = null,
      execute = null;

  final ToolPreview? preview;
  final Future<ToolOutcome> Function()? execute;
  final String? refusal;
  final bool limitReached;
}

/// A tool that changes the user's queue or playlists. [describe] and [call]
/// both go through [plan], so what runs is checked again against the library
/// at that moment, never trusted from the card.
abstract class WriteTool extends AiTool {
  const WriteTool();

  @override
  ToolRisk get risk => ToolRisk.write;

  /// Checks [args] (already schema-valid) and prepares the write.
  Future<WritePlan> plan(Map<String, Object?> args, ToolEnv env);

  @override
  Future<ToolPreview?> describe(Map<String, Object?> args, ToolEnv env) async {
    final problem = validateAgainstSchema(parameters, args);
    if (problem != null) {
      return ToolPreview.refused('invalid arguments: $problem');
    }
    final p = await plan(args, env);
    return p.preview ??
        ToolPreview.refused(p.refusal!, limitReached: p.limitReached);
  }

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final p = await plan(args, env);
    if (p.execute == null) {
      return p.limitReached
          ? ToolOutcome.limit(p.refusal!)
          : ToolOutcome.error(p.refusal!);
    }
    return p.execute!();
  }
}

/// The `trackIds` property of a write schema.
Map<String, Object?> trackIdsProperty(String description) => {
  'type': 'array',
  'items': {'type': 'integer'},
  'maxItems': writeIdsMax,
  'description': description,
};

/// Snapshot of a visible track for a card or a done part. The text comes
/// from tags, so it is cleaned like model text.
TrackRefSnapshot snapshotOf(TrackRow t) => TrackRefSnapshot(
  trackId: t.id,
  title: sanitizeModelText(t.title, maxRunes: 200),
  artist: sanitizeModelText(t.artist ?? '', maxRunes: 200),
  album: t.album == null ? null : sanitizeModelText(t.album!, maxRunes: 200),
);

/// Snapshot of a track that is no longer visible: only its id is known.
TrackRefSnapshot unknownSnapshot(int id) =>
    TrackRefSnapshot(trackId: id, title: '#$id');

/// The visible tracks among the call's `trackIds`, or the refusal.
typedef ResolvedTracks = ({
  List<TrackRow> visible,
  List<int> absent,
  String? refusal,
});

/// Looks every id up through `visibleOf` and checks the turn's add limit.
/// Absent ids are reported, never sent on. No visible track at all is a
/// refusal (the model most likely invented the ids) unless [allowEmpty].
Future<({ResolvedTracks tracks, bool limit})> resolveTracks(
  ToolEnv env,
  List<int> ids, {
  bool allowEmpty = false,
}) async {
  final unique = ids.toSet().toList();
  final found = unique.isEmpty
      ? (visible: <TrackRow>[], absent: <int>[])
      : await env.library.visibleOf(unique);
  if (found.visible.isEmpty && !allowEmpty) {
    return (
      tracks: (
        visible: found.visible,
        absent: found.absent,
        refusal: ids.isEmpty
            ? 'trackIds is empty'
            : 'none of the ids is a song in the library: ${found.absent.join(', ')}',
      ),
      limit: false,
    );
  }
  final usage = await env.turnUsage();
  if (!usage.canAdd(found.visible.length)) {
    return (
      tracks: (
        visible: found.visible,
        absent: found.absent,
        refusal: addLimitText(usage),
      ),
      limit: true,
    );
  }
  return (
    tracks: (visible: found.visible, absent: found.absent, refusal: null),
    limit: false,
  );
}

String addLimitText(TurnItemUsage usage) =>
    'limit reached: at most $maxAddedItemsPerTurn songs can be added in one '
    'turn and ${usage.added} already were; ask the user to send another '
    'message to continue';

String removeLimitText(TurnItemUsage usage) =>
    'limit reached: at most $maxRemovedItemsPerTurn items can be removed in '
    'one turn and ${usage.removed} already were; ask the user to send '
    'another message to continue';

extension WriteArgs on Map<String, Object?> {
  List<int> get trackIds => intList('trackIds');
}
