import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'chat_markdown.dart';
import 'markdown/chat_markdown_model.dart';
import 'markdown/chat_markdown_stream.dart';

/// The answer text as blocks. While [streaming], only the open tail (the group
/// being written and the partial line) is parsed and rebuilt per delta: closed
/// blocks are parsed once and their widgets are reused as they are, so a long
/// answer costs the same per delta as a short one.
class AssistantBlocks extends StatefulWidget {
  const AssistantBlocks({
    super.key,
    required this.text,
    this.streaming = false,
  });

  final String text;
  final bool streaming;

  @override
  State<AssistantBlocks> createState() => _AssistantBlocksState();
}

/// Closed blocks are grouped this many to a widget, so a delta compares one
/// widget per group instead of one per block of a very long answer.
const int _groupSize = 40;

class _AssistantBlocksState extends State<AssistantBlocks> {
  late ChatMarkdownStream _stream;
  // Full groups of closed blocks (never touched again), then the views of the
  // closed blocks that do not fill a group yet.
  final _groups = <Widget>[];
  final _tailViews = <Widget>[];
  Widget? _tailGroup;
  int _built = 0;
  String _fed = '';

  @override
  void initState() {
    super.initState();
    _stream = ChatMarkdownStream();
    _feed(widget.text);
  }

  @override
  void didUpdateWidget(AssistantBlocks old) {
    super.didUpdateWidget(old);
    _feed(widget.text);
  }

  void _feed(String text) {
    if (text == _fed && !_isFinishing) return;
    if (_stream.isFinished || !text.startsWith(_fed)) {
      // The text was replaced, not extended: start over.
      _stream = ChatMarkdownStream();
      _groups.clear();
      _tailViews.clear();
      _tailGroup = null;
      _built = 0;
      _fed = '';
    }
    _stream.add(text.substring(_fed.length));
    _fed = text;
    if (!widget.streaming) _stream.finish();
    final closed = _stream.closedBlocks;
    if (closed.length == _built) return;
    for (; _built < closed.length; _built++) {
      _tailViews.add(ChatBlockView(closed[_built]));
      if (_tailViews.length == _groupSize) {
        _groups.add(_BlockGroup(List.of(_tailViews)));
        _tailViews.clear();
      }
    }
    _tailGroup = _tailViews.isEmpty ? null : _BlockGroup(List.of(_tailViews));
  }

  bool get _isFinishing => !widget.streaming && !_stream.isFinished;

  @override
  Widget build(BuildContext context) {
    final open = widget.streaming ? _stream.openBlocks : const <ChatBlock>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: KSpace.x2,
      children: [
        ..._groups,
        ?_tailGroup,
        for (final b in open) ChatBlockView(b),
      ],
    );
  }
}

class _BlockGroup extends StatelessWidget {
  const _BlockGroup(this.views);

  final List<Widget> views;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: KSpace.x2,
    children: views,
  );
}
