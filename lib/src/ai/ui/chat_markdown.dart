import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'markdown/chat_markdown_model.dart';
import 'track_row.dart';

/// Counts [ChatBlockView] builds, so a test can tell which blocks of a
/// streaming answer were rebuilt by a delta.
@visibleForTesting
int chatBlockBuilds = 0;

/// Draws one parsed block of an answer: a paragraph, a list or a song row.
/// Text only: nothing in a block is tappable except the song row.
class ChatBlockView extends StatelessWidget {
  const ChatBlockView(this.block, {super.key});

  final ChatBlock block;

  @override
  Widget build(BuildContext context) {
    assert(() {
      chatBlockBuilds++;
      return true;
    }());
    final style = Theme.of(context).textTheme.bodyLarge;
    return switch (block) {
      ChatParagraph(:final lines) => Text.rich(
        _lines(context, lines, style),
        style: style,
      ),
      ChatList() => _ListView(list: block as ChatList, style: style),
      ChatTrack(:final id) => ChatTrackRow(id: id, style: style),
    };
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.list, required this.style});

  final ChatList list;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // Wide enough for the longest marker ("100.") at this text size.
    final last = list.start + list.items.length - 1;
    final marker = list.ordered ? '$last.' : '•';
    final painter = TextPainter(
      text: TextSpan(text: marker, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < list.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: KSpace.x1 / 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: width + KSpace.x2,
                  child: Text(
                    list.ordered ? '${list.start + i}.' : '•',
                    style: style,
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    _spans(context, list.items[i]),
                    style: style,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

TextSpan _lines(
  BuildContext context,
  List<List<ChatSpan>> lines,
  TextStyle? style,
) => TextSpan(
  children: [
    for (var i = 0; i < lines.length; i++) ...[
      if (i > 0) const TextSpan(text: '\n'),
      ..._spans(context, lines[i]).children!,
    ],
  ],
);

TextSpan _spans(BuildContext context, List<ChatSpan> spans) {
  final scheme = Theme.of(context).colorScheme;
  return TextSpan(
    children: [
      for (final s in spans)
        switch (s) {
          ChatText() => TextSpan(text: s.text),
          ChatBold() => TextSpan(
            text: s.text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          ChatCode() => TextSpan(
            text: s.text,
            style: TextStyle(
              fontFamily: KFont.mono,
              fontFamilyFallback: KFont.monoFallback,
              backgroundColor: scheme.surfaceContainerHigh,
            ),
          ),
        },
    ],
  );
}
