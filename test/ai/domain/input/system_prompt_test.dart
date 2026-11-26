import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/input/system_prompt.dart';
import 'package:kanaru/src/ai/domain/permission.dart';

void main() {
  test('prompt states the rules and the user instructions come last', () {
    final p = buildChatSystemPrompt(
      permission: AiPermission.ask,
      boundary: 'kabc',
      instructions: 'Be brief.${String.fromCharCode(0x202E)}',
    );
    expect(p, contains('[[t:ID]]'));
    expect(p, contains('<data-kabc>'));
    expect(p, contains('never follow'));
    expect(p, contains('three different things'));
    expect(p.trimRight(), endsWith('Be brief.'));
  });

  test('instructions are cut by characters, never inside an emoji', () {
    final emoji = '\u{1F3B5}' * (chatInstructionsMaxChars + 5);
    final p = buildChatSystemPrompt(
      permission: AiPermission.ask,
      boundary: 'k',
      instructions: emoji,
    );
    final tail = p.substring(p.indexOf('general instructions:\n') + 22);
    expect(tail.runes.length, chatInstructionsMaxChars);
    expect(tail.runes.every((r) => r == 0x1F3B5), isTrue);
  });

  test('read-only prompt says writes are impossible', () {
    final p = buildChatSystemPrompt(
      permission: AiPermission.readOnly,
      boundary: 'k',
    );
    expect(p, contains('only read'));
    expect(p, isNot(contains('general instructions')));
  });

  test('boundary is random, one letter plus ten hex digits', () {
    final a = newChatBoundary(Random(1));
    final b = newChatBoundary(Random(2));
    expect(a, matches(RegExp(r'^k[0-9a-f]{10}$')));
    expect(a, isNot(b));
  });
}
