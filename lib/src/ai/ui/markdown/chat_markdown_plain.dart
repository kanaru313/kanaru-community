import 'chat_markdown_model.dart';
import 'chat_markdown_stream.dart';

/// Ids of the `[[t:ID]]` lines of [markdown], as typed.
List<String> trackTokensOf(String markdown) => [
  for (final b in parseBlocks(markdown))
    if (b is ChatTrack) b.id else if (b is ChatTrackList) ...b.ids,
];

/// The answer as it reads on screen, for the clipboard: markers (`**`, `` ` ``,
/// list syntax) are dropped, a `[[t:ID]]` line becomes the label
/// [trackLabel] gives for its id ("title – artist"), and a line without a
/// label (unknown song, unreadable id) is left out.
String plainAnswerText(
  String markdown, {
  required String? Function(String id) trackLabel,
}) {
  final out = StringBuffer();
  ChatBlock? previous;
  for (final block in parseBlocks(markdown)) {
    final text = switch (block) {
      ChatParagraph(:final lines) => lines.map(_line).join('\n'),
      ChatList(:final ordered, :final start, :final items) => [
        for (var i = 0; i < items.length; i++)
          '${ordered ? '${start + i}.' : '•'} ${_line(items[i])}',
      ].join('\n'),
      ChatTrack(:final id) => trackLabel(id) ?? '',
      ChatTrackList(:final ids) =>
        ids.map(trackLabel).whereType<String>().join('\n'),
    };
    if (text.isEmpty) continue;
    if (previous != null) {
      // Song lines stay a run; other blocks are set apart by a blank line.
      out.write(_isSong(previous) && _isSong(block) ? '\n' : '\n\n');
    }
    out.write(text);
    previous = block;
  }
  return out.toString();
}

bool _isSong(ChatBlock b) => b is ChatTrack || b is ChatTrackList;

String _line(List<ChatSpan> spans) => spans.map((s) => s.text).join();
