import '../conversation/parts.dart';
import '../tools/tool_env.dart';
import 'data_fence.dart';
import 'template_analysis.dart';
import 'variable_catalog.dart';
import 'variable_values.dart';

/// Why a text with variables was not sent.
sealed class FillIssue {
  const FillIssue();
}

/// The variable has no value now ([reason] is a short English phrase).
class FillMissing extends FillIssue {
  const FillMissing(this.variable, this.reason);

  final AiVariable variable;
  final String reason;
}

/// The variable's privacy group is off and the user did not allow bypass.
class FillGroupOff extends FillIssue {
  const FillGroupOff(this.variable);

  final AiVariable variable;
}

/// `{{input}}` is still in the text: the user has to type it first.
class FillLeftoverInput extends FillIssue {
  const FillLeftoverInput();
}

sealed class FillResult {
  const FillResult();
}

/// Ready to send: [parts] alternate the user's words ([TextPart]) and the
/// fenced values ([DataPart]); [displayText] shows the values inline (for
/// the conversation title). [shortened] lists variables sent in short form.
class FillDone extends FillResult {
  const FillDone({
    required this.parts,
    required this.displayText,
    this.shortened = const {},
  });

  final List<AiPart> parts;
  final String displayText;
  final Set<AiVariable> shortened;
}

/// Nothing is sent: every reason that applies.
class FillBlocked extends FillResult {
  const FillBlocked(this.issues);

  final List<FillIssue> issues;
}

/// Some values are over the budget; sending again with `shortVersion: true`
/// sends their short form (queue: 50 entries around the loaded one).
class FillOversize extends FillResult {
  const FillOversize(this.variables);

  final List<AiVariable> variables;
}

/// Fills the `{{variables}}` of [text] at send time.
///
/// - A known variable whose group is off blocks the send unless [varBypass].
/// - A known variable with no value blocks it, with the reason.
/// - `{{input}}` left in the text blocks it.
/// - An unknown `{{x}}` stays as written (literal text of the composer).
/// - A value over [maxBytes] (UTF-8) asks for the short version
///   ([FillOversize]); with [shortVersion] it is used.
/// - Every value becomes a fenced [DataPart] with the variable's source; the
///   user's own words stay [TextPart]s.
Future<FillResult> fillVariables({
  required String text,
  required ToolEnv env,
  required ToolGroupSwitches groupEnabled,
  required bool varBypass,
  bool shortVersion = false,
  int maxBytes = variableValueMaxBytes,
}) async {
  final spans = analyzeTemplate(
    text,
    groupEnabled,
  ).spans.where((s) => s.variable != null).toList();
  if (spans.isEmpty) {
    return FillDone(
      parts: [if (text.isNotEmpty) TextPart(text)],
      displayText: text,
    );
  }

  final issues = <FillIssue>[];
  final reads = <AiVariable, VariableRead>{};
  for (final s in spans) {
    final v = s.variable!;
    if (v == AiVariable.input) {
      if (!issues.any((i) => i is FillLeftoverInput)) {
        issues.add(const FillLeftoverInput());
      }
      continue;
    }
    if (s.kind == TemplateSpanKind.groupOff && !varBypass) {
      if (!issues.any((i) => i is FillGroupOff && i.variable == v)) {
        issues.add(FillGroupOff(v));
      }
      continue;
    }
    if (reads.containsKey(v)) continue;
    final read = await readVariable(v, env);
    reads[v] = read;
    if (read is VariableMissing) issues.add(FillMissing(v, read.reason));
  }
  if (issues.isNotEmpty) return FillBlocked(issues);

  final over = [
    for (final e in reads.entries)
      if (e.value is VariableFound &&
          utf8Length((e.value as VariableFound).full) > maxBytes)
        e.key,
  ];
  if (over.isNotEmpty && !shortVersion) return FillOversize(over);

  final parts = <AiPart>[];
  final display = StringBuffer();
  final shortened = <AiVariable>{};
  var cursor = 0;
  void literal(String s) {
    if (s.isEmpty) return;
    parts.add(TextPart(s));
    display.write(s);
  }

  for (final s in spans) {
    literal(text.substring(cursor, s.start));
    cursor = s.end;
    final found = reads[s.variable!]! as VariableFound;
    final useShort = over.contains(s.variable);
    if (useShort) shortened.add(s.variable!);
    var value = useShort ? found.short : found.full;
    value = clipUtf8(value, maxBytes);
    parts.add(fencedData(s.variable!.source, value));
    display.write(fenceText(value));
  }
  literal(text.substring(cursor));
  return FillDone(
    parts: parts,
    displayText: display.toString(),
    shortened: shortened,
  );
}
