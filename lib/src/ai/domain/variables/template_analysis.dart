import 'variable_catalog.dart';

/// How one `{{...}}` of a text reads.
enum TemplateSpanKind {
  /// A known variable whose privacy group is on (or that needs none).
  ok,

  /// Not a variable of the catalogue.
  unknown,

  /// A known variable whose privacy group is off.
  groupOff,
}

/// One `{{...}}` found in a text; [start] / [end] are string indexes of the
/// whole `{{...}}` (end exclusive).
class TemplateSpan {
  const TemplateSpan({
    required this.start,
    required this.end,
    required this.name,
    required this.kind,
    this.variable,
  });

  final int start;
  final int end;

  /// The trimmed text between the braces.
  final String name;
  final TemplateSpanKind kind;

  /// Set for [TemplateSpanKind.ok] and [TemplateSpanKind.groupOff].
  final AiVariable? variable;
}

class TemplateAnalysis {
  const TemplateAnalysis(this.spans);

  final List<TemplateSpan> spans;

  Iterable<TemplateSpan> get unknown =>
      spans.where((s) => s.kind == TemplateSpanKind.unknown);

  Iterable<TemplateSpan> get groupOff =>
      spans.where((s) => s.kind == TemplateSpanKind.groupOff);

  /// A saved template or prompt is in error when it names an unknown
  /// variable ("Biến lỗi"). A group that is off is a state, not an error.
  bool get invalidAsSaved => unknown.isNotEmpty;
}

final _braces = RegExp(r'\{\{([^{}]*)\}\}');

/// Reads the `{{variables}}` of [body] against the user's group switches.
///
/// One rule everywhere: an unknown `{{x}}` is plain text when sent from the
/// composer (the filler leaves it as written) and an error in a saved
/// template ([TemplateAnalysis.invalidAsSaved]).
TemplateAnalysis analyzeTemplate(String body, ToolGroupSwitches switches) {
  final spans = <TemplateSpan>[];
  for (final m in _braces.allMatches(body)) {
    final name = m[1]!.trim();
    final variable = AiVariable.fromName(name);
    final kind = variable == null
        ? TemplateSpanKind.unknown
        : (variable.group != null && !switches(variable.group!))
        ? TemplateSpanKind.groupOff
        : TemplateSpanKind.ok;
    spans.add(
      TemplateSpan(
        start: m.start,
        end: m.end,
        name: name,
        kind: kind,
        variable: variable,
      ),
    );
  }
  return TemplateAnalysis(spans);
}
