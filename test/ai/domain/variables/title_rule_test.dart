import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/variables/title_rule.dart';

void main() {
  test('short text stays whole', () {
    expect(conversationTitle('Hello\n there'), 'Hello there');
  });

  test('long text is cut at 40 characters with an ellipsis', () {
    final t = conversationTitle('a' * 60);
    expect(t, '${'a' * 40}…');
  });

  test('controls and bidi are removed', () {
    final raw = 'a${String.fromCharCode(0x202E)}b${String.fromCharCode(7)}c';
    expect(conversationTitle(raw), 'abc');
  });
}
