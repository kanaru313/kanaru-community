import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/variables/template_analysis.dart';
import 'package:kanaru/src/ai/domain/variables/variable_filler.dart';

import '../tools/fake_tool_env.dart';

void main() {
  test('unknown variable flagged in a saved template', () {
    final a = analyzeTemplate('hi {{title}} {{ nope }}', (_) => true);
    expect(a.invalidAsSaved, isTrue);
    expect(a.unknown.single.name, 'nope');
    expect(a.spans.map((s) => s.kind), [
      TemplateSpanKind.ok,
      TemplateSpanKind.unknown,
    ]);
  });

  test('disabled group flagged groupOff', () {
    final a = analyzeTemplate(
      '{{lyrics}} {{input}} {{queue}}',
      (g) => g != AiToolGroup.lyrics,
    );
    expect(a.spans.map((s) => s.kind), [
      TemplateSpanKind.groupOff,
      TemplateSpanKind.ok,
      TemplateSpanKind.ok,
    ]);
    expect(a.invalidAsSaved, isFalse);
    expect(a.spans.first.start, 0);
    expect(a.spans.first.end, 10);
  });

  test('composer treats unknown as literal', () async {
    final text = 'say {{nope}}';
    expect(analyzeTemplate(text, (_) => true).invalidAsSaved, isTrue);
    final r = await fillVariables(
      text: text,
      env: fakeEnv(),
      groupEnabled: (_) => true,
      varBypass: false,
    );
    expect((r as FillDone).parts, [const TextPart('say {{nope}}')]);
  });
}
