import 'dart:convert';

import '../domain/conversation/track_ref_snapshot.dart';

/// What the open tool card shows as the result.
sealed class ToolResultView {
  const ToolResultView();
}

/// A list of songs (search, queue, playlist, most played): one compact song
/// row each, every row the call returned.
final class ToolSongs extends ToolResultView {
  const ToolSongs(this.tracks);

  final List<TrackRefSnapshot> tracks;
}

/// A list of anything else (playlists): one short text line per row.
final class ToolLines extends ToolResultView {
  const ToolLines(this.lines);

  final List<String> lines;
}

/// Not a list: the text, cut to a size a card can hold.
final class ToolText extends ToolResultView {
  const ToolText(this.text);

  final String text;
}

const _maxPlainChars = 1500;

/// Where a tool puts the song in its `|` rows: (track id, title, artist)
/// cell indexes. Only the tools that list songs are here.
const _songCells = <String, (int, int, int)>{
  'search_library': (0, 1, 2),
  'get_queue': (1, 2, 3),
  'get_playlist_tracks': (1, 2, 3),
  'get_listening_stats': (1, 2, 3),
};

/// Whether [tool] returns song rows.
bool isSongListTool(String tool) => _songCells.containsKey(tool);

/// The result of tool [tool] as the open card shows it.
ToolResultView toolResultView(String tool, String resultText) {
  final text = resultText.trim();
  final items = itemsOfToolResult(text);
  if (items == null) {
    return ToolText(
      text.length > _maxPlainChars
          ? '${text.substring(0, _maxPlainChars)}…'
          : text,
    );
  }
  final cells = _songCells[tool];
  if (cells != null) {
    final songs = <TrackRefSnapshot>[];
    for (final row in items) {
      final c = splitToolRow(row);
      if (c.length <= cells.$2) break;
      songs.add(
        TrackRefSnapshot(
          trackId: int.tryParse(c[cells.$1]) ?? 0,
          title: c[cells.$2],
          artist: c.length > cells.$3 ? c[cells.$3] : '',
        ),
      );
    }
    if (songs.length == items.length) return ToolSongs(songs);
  }
  return ToolLines([for (final r in items) r.replaceAll('|', ' | ')]);
}

/// Rows of a list result, or null when [text] is not one.
List<String>? itemsOfToolResult(String text) {
  try {
    final json = jsonDecode(text);
    if (json is Map && json['items'] is List) {
      return [for (final r in json['items'] as List) '$r'];
    }
  } on FormatException {
    // Not JSON: shown as text.
  }
  return null;
}

/// Cells of a tool row: split at `|`, with the escapes of a cell (`\|`, `\\`,
/// `\n`, `\r`) undone.
List<String> splitToolRow(String row) {
  final cells = <String>[];
  final cell = StringBuffer();
  for (var i = 0; i < row.length; i++) {
    final c = row[i];
    if (c == r'\' && i + 1 < row.length) {
      final n = row[++i];
      cell.write(switch (n) {
        'n' => '\n',
        'r' => '\r',
        '|' || r'\' => n,
        _ => '\\$n',
      });
    } else if (c == '|') {
      cells.add(cell.toString());
      cell.clear();
    } else {
      cell.write(c);
    }
  }
  cells.add(cell.toString());
  return cells;
}
