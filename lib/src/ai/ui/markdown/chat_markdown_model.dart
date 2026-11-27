// What the assistant's answer is made of after parsing. Pure Dart: no Flutter
// import, and no field holds a URL, so nothing parsed from a model's text can
// become a tap target.

/// A run of text inside a line.
sealed class ChatSpan {
  const ChatSpan(this.text);

  final String text;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ChatSpan &&
      other.text == text;

  @override
  int get hashCode => Object.hash(runtimeType, text);

  @override
  String toString() => '$runtimeType($text)';
}

/// Plain text. Italic markers are already removed from it.
final class ChatText extends ChatSpan {
  const ChatText(super.text);
}

/// `**bold**`.
final class ChatBold extends ChatSpan {
  const ChatBold(super.text);
}

/// `` `code` ``.
final class ChatCode extends ChatSpan {
  const ChatCode(super.text);
}

/// A block of the answer.
sealed class ChatBlock {
  const ChatBlock();
}

/// Consecutive text lines; each source line stays a line break.
final class ChatParagraph extends ChatBlock {
  const ChatParagraph(this.lines);

  final List<List<ChatSpan>> lines;

  @override
  bool operator ==(Object other) =>
      other is ChatParagraph && _same(other.lines, lines);

  @override
  int get hashCode => Object.hash('p', lines.length);

  @override
  String toString() => 'ChatParagraph($lines)';
}

/// A bullet or numbered list (one level). [start] is the number of the first
/// item of an ordered list.
final class ChatList extends ChatBlock {
  const ChatList({
    required this.ordered,
    required this.start,
    required this.items,
  });

  final bool ordered;
  final int start;
  final List<List<ChatSpan>> items;

  @override
  bool operator ==(Object other) =>
      other is ChatList &&
      other.ordered == ordered &&
      other.start == start &&
      _same(other.items, items);

  @override
  int get hashCode => Object.hash('l', ordered, start, items.length);

  @override
  String toString() => 'ChatList(ordered: $ordered, $start, $items)';
}

/// A `[[t:ID]]` line. [id] is the raw token; the screen decides whether it is
/// a track of this conversation.
final class ChatTrack extends ChatBlock {
  const ChatTrack(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is ChatTrack && other.id == id;

  @override
  int get hashCode => Object.hash('t', id);

  @override
  String toString() => 'ChatTrack($id)';
}

/// Song lines in a row (no other line between). Only a run of more than
/// [chatListMaxRows] lines is one of these (the screen gives it a box of its
/// own with its own scroll); a shorter run stays single [ChatTrack] blocks.
final class ChatTrackList extends ChatBlock {
  const ChatTrackList(this.ids);

  final List<String> ids;

  @override
  bool operator ==(Object other) =>
      other is ChatTrackList && _sameIds(other.ids, ids);

  @override
  int get hashCode => Object.hash('tl', ids.length, ids.first);

  @override
  String toString() => 'ChatTrackList($ids)';
}

/// A song list longer than this many rows gets a box of this height with its
/// own scroll; a shorter one is shown whole.
const int chatListMaxRows = 8;

bool _sameIds(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _same(List<List<ChatSpan>> a, List<List<ChatSpan>> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.length != y.length) return false;
    for (var j = 0; j < x.length; j++) {
      if (x[j] != y[j]) return false;
    }
  }
  return true;
}
