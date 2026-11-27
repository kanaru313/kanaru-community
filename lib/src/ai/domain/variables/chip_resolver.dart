import 'dart:math' as math;

import '../conversation/parts.dart';
import '../settings/tool_groups.dart';
import '../tools/tool_env.dart';
import '../tools/tool_rows.dart';
import 'chip_ref.dart';
import 'data_fence.dart';
import 'variable_catalog.dart';
import 'variable_values.dart';

/// Reads that need library keys the tool ports do not take (album, artist,
/// genre, language keys and playlist uids). Implemented in `ai/data` on the
/// library's public APIs.
abstract interface class ChipScopePort {
  /// The id the model uses for the playlist with [uid]; null when it is gone
  /// or not writable.
  Future<int?> playlistModelId(String uid);

  /// The visible tracks of an album, artist, genre or language chip, in the
  /// library's order, with the count of all of them; null when it is gone.
  /// [ref] is the chip's key (`''` for "no language").
  Future<({List<TrackRow> rows, int total})?> scopeTracks(
    ChipKind kind,
    String ref,
  );
}

sealed class ChipResolution {
  const ChipResolution();
}

/// The chip is ready: [chip] is stored on the message, [data] is sent.
class ChipResolved extends ChipResolution {
  const ChipResolved({required this.chip, required this.data});

  final ChipPart chip;
  final DataPart data;
}

/// The chip's privacy group is off.
class ChipBlocked extends ChipResolution {
  const ChipBlocked(this.group);

  final AiToolGroup group;
}

/// What the chip points at is gone or empty ([reason]: short English).
class ChipMissing extends ChipResolution {
  const ChipMissing(this.reason);

  final String reason;
}

/// Most rows one chip sends.
const int chipMaxRows = 200;

/// Turns a chip into the fenced data the model reads. Chip data goes through
/// the same group switches and bypass as the variables.
class ChipResolver {
  const ChipResolver({
    required this.env,
    required this.scopes,
    required this.groupEnabled,
    required this.varBypass,
    this.maxBytes = variableValueMaxBytes,
  });

  final ToolEnv env;
  final ChipScopePort scopes;
  final ToolGroupSwitches groupEnabled;
  final bool varBypass;
  final int maxBytes;

  Future<ChipResolution> resolve(ChipRef chip) async {
    final group = chip.group;
    if (!varBypass && !groupEnabled(group)) return ChipBlocked(group);
    return switch (chip.kind) {
      ChipKind.nowPlaying => _nowPlaying(chip),
      ChipKind.song || ChipKind.songs => _songs(chip),
      ChipKind.playlist => _playlist(chip),
      _ => _scope(chip),
    };
  }

  ChipResolution _done(
    ChipRef chip,
    DataSource source,
    String text, {
    String? ref,
  }) => ChipResolved(
    chip: ChipPart(
      kind: chip.kind,
      ref: ref ?? chip.ref,
      label: chip.label,
      tracks: chip.tracks,
    ),
    data: fencedData(source, clipUtf8(text, maxBytes)),
  );

  Future<ChipResolution> _nowPlaying(ChipRef chip) async {
    final read = await readNowPlaying(env);
    if (read is! VariableFound) {
      return ChipMissing((read as VariableMissing).reason);
    }
    return _done(chip, DataSource.nowPlaying, read.full);
  }

  Future<ChipResolution> _songs(ChipRef chip) async {
    final ids = [for (final t in chip.tracks) t.trackId];
    final r = await env.library.details(ids);
    if (r.found.isEmpty) {
      return const ChipMissing('the songs are not available');
    }
    final rows = [
      for (final d in r.found.take(chipMaxRows))
        joinRow([
          d.row.id,
          d.row.title,
          d.row.artist,
          d.row.album,
          d.row.year,
          d.genre,
          d.language,
        ]),
    ];
    final total = math.max(
      r.found.length,
      chip.kind == ChipKind.songs ? songsChipTotal(chip.label) ?? 0 : 0,
    );
    return _done(
      chip,
      DataSource.track,
      [
        'rows: id|title|artist|album|year|genre|language',
        // The model must not read a cut list as the whole selection: name the
        // real size (a selection cut before it got here knows it from its
        // label) and how many rows follow.
        if (total > rows.length) ...[
          'total: $total',
          'listed: ${rows.length}',
          'note: only the first ${rows.length} selected songs are listed',
        ],
        ...rows,
      ].join('\n'),
    );
  }

  Future<ChipResolution> _scope(ChipRef chip) async {
    final ref = chip.ref;
    if (ref == null) return const ChipMissing('the chip has no key');
    final r = await scopes.scopeTracks(chip.kind, ref);
    if (r == null || r.rows.isEmpty) {
      return const ChipMissing('no songs are available for it');
    }
    final source = switch (chip.kind) {
      ChipKind.album => DataSource.album,
      ChipKind.artist => DataSource.artist,
      ChipKind.genre => DataSource.genre,
      _ => DataSource.language,
    };
    return _done(chip, source, _listText(chip.label, r.rows, r.total));
  }

  Future<ChipResolution> _playlist(ChipRef chip) async {
    final uid = chip.ref;
    if (uid == null) return const ChipMissing('the chip has no key');
    final id = await scopes.playlistModelId(uid);
    if (id == null) return const ChipMissing('the playlist is not available');
    final entries = await env.playlists.entries(id);
    if (entries == null) {
      return const ChipMissing('the playlist is not available');
    }
    return _done(
      chip,
      DataSource.playlist,
      [
        'playlist: $id',
        _listText(entries.name, [
          for (final e in entries.entries) e.track,
        ], entries.entries.length),
      ].join('\n'),
      ref: '$id',
    );
  }

  String _listText(String? name, List<TrackRow> rows, int total) => [
    if (name != null && name.isNotEmpty) 'name: ${escapeCell(name)}',
    'rows: id|title|artist|album|year',
    'total: $total',
    for (final t in rows.take(chipMaxRows)) trackRowText(t),
  ].join('\n');
}
