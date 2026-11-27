import 'chat_markdown_model.dart';

/// A line longer than this (UTF-16 units) is one plain text span: inline
/// rules are quadratic in the worst case, and a model line that long is not
/// prose. The same cap applies to a streamed line, so both paths agree.
const int chatMarkdownMaxLine = 4096;

enum _Kind { text, code, star }

class _Tok {
  _Tok.text(this.text) : kind = _Kind.text, len = 0;
  _Tok.code(this.text) : kind = _Kind.code, len = 0;
  _Tok.star(this.len, {required this.canOpen, required this.canClose})
    : kind = _Kind.star,
      text = '*' * len;

  final _Kind kind;
  final String text;
  final int len;
  bool canOpen = false;
  bool canClose = false;

  /// Index of the opener (for a closer) or closer (for an opener); null when
  /// the marker stayed unpaired and shows as typed.
  int? mate;
  bool opens = false;
}

bool _blank(String ch) => ch.trim().isEmpty;

/// Parses one line: code spans, `**bold**`, and `*x*` (markers dropped, text
/// plain). `_` is never a marker. Everything else, links and HTML included, is
/// the text as typed.
List<ChatSpan> parseInline(String line) {
  if (line.length > chatMarkdownMaxLine) return [ChatText(line)];
  final tokens = _tokenize(line);
  _pair(tokens);
  return _emit(tokens);
}

List<_Tok> _tokenize(String line) {
  final out = <_Tok>[];
  final text = StringBuffer();
  void flush() {
    if (text.isEmpty) return;
    out.add(_Tok.text(text.toString()));
    text.clear();
  }

  var i = 0;
  while (i < line.length) {
    final c = line[i];
    if (c == '`') {
      var n = 1;
      while (i + n < line.length && line[i + n] == '`') {
        n++;
      }
      final close = _closingRun(line, i + n, n);
      if (close < 0) {
        text.write('`' * n);
      } else {
        flush();
        out.add(_Tok.code(line.substring(i + n, close)));
        i = close + n;
        continue;
      }
      i += n;
    } else if (c == '*') {
      var n = 1;
      while (i + n < line.length && line[i + n] == '*') {
        n++;
      }
      if (n > 2) {
        text.write('*' * n);
      } else {
        flush();
        final before = i > 0 ? line[i - 1] : null;
        final after = i + n < line.length ? line[i + n] : null;
        out.add(
          _Tok.star(
            n,
            canOpen: after != null && !_blank(after),
            canClose: before != null && !_blank(before),
          ),
        );
      }
      i += n;
    } else {
      text.write(c);
      i++;
    }
  }
  flush();
  return out;
}

/// Index of the next backtick run of exactly [n] at or after [from], or -1.
int _closingRun(String line, int from, int n) {
  var j = from;
  while (true) {
    final k = line.indexOf('`', j);
    if (k < 0) return -1;
    var m = 1;
    while (k + m < line.length && line[k + m] == '`') {
      m++;
    }
    if (m == n) return k;
    j = k + m;
  }
}

/// Pairs each closing `*` run with the nearest opener of the same length.
void _pair(List<_Tok> tokens) {
  final open = <int>[];
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (t.kind != _Kind.star) continue;
    if (t.canClose) {
      final p = open.lastIndexWhere((o) => tokens[o].len == t.len);
      if (p >= 0) {
        final o = open[p];
        tokens[o].mate = i;
        tokens[o].opens = true;
        t.mate = o;
        // Openers between the pair never found a closer: they stay literal.
        open.removeRange(p, open.length);
        continue;
      }
    }
    if (t.canOpen) open.add(i);
  }
}

List<ChatSpan> _emit(List<_Tok> tokens) {
  final out = <ChatSpan>[];
  var bold = 0;
  void add(String text, {required bool isBold}) {
    if (text.isEmpty) return;
    final last = out.isEmpty ? null : out.last;
    if (isBold && last is ChatBold) {
      out[out.length - 1] = ChatBold(last.text + text);
    } else if (!isBold && last is ChatText) {
      out[out.length - 1] = ChatText(last.text + text);
    } else {
      out.add(isBold ? ChatBold(text) : ChatText(text));
    }
  }

  for (final t in tokens) {
    switch (t.kind) {
      case _Kind.text:
        add(t.text, isBold: bold > 0);
      case _Kind.code:
        out.add(ChatCode(t.text));
      case _Kind.star:
        if (t.mate == null) {
          add(t.text, isBold: bold > 0);
        } else if (t.len == 2) {
          bold += t.opens ? 1 : -1;
        }
      // A paired single `*` only drops its markers.
    }
  }
  return out;
}
