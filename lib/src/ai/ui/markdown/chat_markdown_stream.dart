import 'chat_markdown_block.dart';
import 'chat_markdown_model.dart';

/// Incremental parser for an answer that streams in. Completed blocks are
/// built once and never change (same objects on every read); only the blocks
/// of the open group, with the partial last line, are rebuilt per delta, so
/// the cost of a delta follows the current group, not the whole answer.
///
/// Rules shared with [parseBlocks] (which feeds this class): a blank line
/// closes the group of lines before it, except after a list item, where the
/// group stays open until the next line shows whether the list goes on
/// (`1.`, blank, `2.` is one list).
class ChatMarkdownStream {
  final _closed = <ChatBlock>[];
  final _group = <ChatLine>[];
  final _partial = StringBuffer();
  bool _pendingBlank = false;
  bool _afterCr = false;
  bool _finished = false;

  /// Completed lines classified so far (a test hook: each completed line is
  /// parsed exactly once).
  int linesClassified = 0;

  /// [finish] was called.
  bool get isFinished => _finished;

  /// Blocks that can no longer change; only grows.
  List<ChatBlock> get closedBlocks => _closed;

  /// Blocks of the open group and the partial line; rebuilt per delta.
  List<ChatBlock> get openBlocks {
    final partial = _partial.toString();
    if (partial.trim().isEmpty) return assembleBlocks(_group);
    final prev = _group.isEmpty ? null : _group.last;
    final line = classifyLine(partial, prev: prev, afterBlank: _pendingBlank);
    if (_pendingBlank && !_continuesList(line, prev)) {
      return [
        ...assembleBlocks(_group),
        ...assembleBlocks([line]),
      ];
    }
    return assembleBlocks([..._group, line]);
  }

  /// Adds streamed text. `\r\n`, `\r` and `\n` end a line; a `\r` and `\n`
  /// arriving in different deltas count as one break.
  void add(String delta) {
    assert(!_finished, 'add after finish');
    for (var i = 0; i < delta.length; i++) {
      final c = delta[i];
      if (c == '\r') {
        _endLine();
        _afterCr = true;
        continue;
      }
      final skip = c == '\n' && _afterCr;
      _afterCr = false;
      if (skip) continue;
      if (c == '\n') {
        _endLine();
      } else {
        _partial.write(c);
      }
    }
  }

  /// The text is complete: the partial line counts and the open group closes.
  void finish() {
    if (_finished) return;
    _finished = true;
    if (_partial.isNotEmpty) _endLine();
    _closeGroup();
  }

  void _endLine() {
    final raw = _partial.toString();
    _partial.clear();
    linesClassified++;
    if (raw.trim().isEmpty) {
      if (_group.isEmpty) return;
      if (_group.last.listOrdered != null) {
        _pendingBlank = true;
      } else {
        _closeGroup();
      }
      return;
    }
    final prev = _group.isEmpty ? null : _group.last;
    final line = classifyLine(raw, prev: prev, afterBlank: _pendingBlank);
    if (_pendingBlank && !_continuesList(line, prev)) _closeGroup();
    _pendingBlank = false;
    _group.add(line);
  }

  bool _continuesList(ChatLine line, ChatLine? prev) =>
      line.isItem && prev != null && line.listOrdered == prev.listOrdered;

  void _closeGroup() {
    _closed.addAll(assembleBlocks(_group));
    _group.clear();
    _pendingBlank = false;
  }
}

/// Parses a whole [markdown] text.
List<ChatBlock> parseBlocks(String markdown) {
  final stream = ChatMarkdownStream()
    ..add(markdown)
    ..finish();
  return List.of(stream.closedBlocks);
}
