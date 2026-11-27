import 'chat_markdown_inline.dart';
import 'chat_markdown_model.dart';

enum ChatLineKind { track, bullet, ordered, cont, text }

/// One non-blank source line, classified and inline-parsed once.
class ChatLine {
  const ChatLine({
    required this.kind,
    required this.spans,
    this.number = 1,
    this.id = '',
    this.listOrdered,
  });

  final ChatLineKind kind;
  final List<ChatSpan> spans;

  /// First number of an ordered item.
  final int number;

  /// Track token of a [ChatLineKind.track] line.
  final String id;

  /// Kind of the list this line belongs to (item or its continuation);
  /// null outside a list.
  final bool? listOrdered;

  bool get isItem =>
      kind == ChatLineKind.bullet || kind == ChatLineKind.ordered;
}

// A track line may carry a list marker (`- `, `* `, `+ `, `1. `, `1) `): a
// model often writes one citation per list item, and the row replaces the item.
final _trackRe = RegExp(
  r'^\s{0,3}(?:(?:[-*+]|\d{1,9}[.)])\s+)?\[\[t:([^\]\s]{1,64})\]\]\s*$',
);
final _bulletRe = RegExp(r'^\s{0,3}[-*+]\s+(.*)$');
final _orderedRe = RegExp(r'^\s{0,3}(\d{1,9})[.)]\s+(.*)$');
final _contRe = RegExp(r'^\s{2,}\S');

/// Classifies one non-blank [raw] line. [prev] is the line before it in the
/// same group; [afterBlank] says a blank line came between them (an indented
/// line then starts a paragraph instead of continuing an item).
ChatLine classifyLine(
  String raw, {
  required ChatLine? prev,
  required bool afterBlank,
}) {
  final track = _trackRe.firstMatch(raw);
  if (track != null) {
    return ChatLine(kind: ChatLineKind.track, spans: const [], id: track[1]!);
  }
  final bullet = _bulletRe.firstMatch(raw);
  if (bullet != null) {
    return ChatLine(
      kind: ChatLineKind.bullet,
      spans: parseInline(bullet[1]!.trim()),
      listOrdered: false,
    );
  }
  final ordered = _orderedRe.firstMatch(raw);
  if (ordered != null) {
    return ChatLine(
      kind: ChatLineKind.ordered,
      spans: parseInline(ordered[2]!.trim()),
      number: int.parse(ordered[1]!),
      listOrdered: true,
    );
  }
  final inList = prev?.listOrdered;
  if (!afterBlank && inList != null && _contRe.hasMatch(raw)) {
    return ChatLine(
      kind: ChatLineKind.cont,
      spans: parseInline(raw.trim()),
      listOrdered: inList,
    );
  }
  return ChatLine(kind: ChatLineKind.text, spans: parseInline(raw.trim()));
}

/// Turns the lines of one group into blocks: consecutive text lines are one
/// paragraph, consecutive items of one kind one list, a track line a block of
/// its own. Cheap: every line is parsed already.
List<ChatBlock> assembleBlocks(List<ChatLine> lines) {
  final out = <ChatBlock>[];
  List<List<ChatSpan>>? para;
  List<List<ChatSpan>>? items;
  var ordered = false;
  var start = 1;

  void flush() {
    if (para != null) out.add(ChatParagraph(para!));
    if (items != null) {
      out.add(ChatList(ordered: ordered, start: start, items: items!));
    }
    para = null;
    items = null;
  }

  for (final line in lines) {
    switch (line.kind) {
      case ChatLineKind.track:
        flush();
        out.add(ChatTrack(line.id));
      case ChatLineKind.text:
        if (items != null) flush();
        (para ??= []).add(line.spans);
      case ChatLineKind.bullet || ChatLineKind.ordered:
        final isOrdered = line.kind == ChatLineKind.ordered;
        if (para != null || (items != null && ordered != isOrdered)) flush();
        if (items == null) {
          items = [];
          ordered = isOrdered;
          start = line.number;
        }
        items!.add(line.spans);
      case ChatLineKind.cont:
        final list = items;
        if (list != null && list.isNotEmpty) {
          list[list.length - 1] = [
            ...list.last,
            const ChatText('\n'),
            ...line.spans,
          ];
        } else {
          (para ??= []).add(line.spans);
        }
    }
  }
  flush();
  return out;
}
