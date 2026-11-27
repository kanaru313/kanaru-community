import '../../../ai/domain/variables/template_analysis.dart';
import '../../../ai/domain/variables/variable_catalog.dart';

/// How one piece of the preview reads.
enum PreviewKind {
  /// Plain text of the prompt.
  text,

  /// A variable filled with its sample value.
  value,

  /// `{{input}}`: the place the user types next.
  input,

  /// A variable of a tool group that is off, filled with its sample value.
  off,

  /// `{{x}}` that is no variable, shown as typed.
  unknown,
}

class PreviewSegment {
  const PreviewSegment(this.kind, this.text, [this.variable]);

  final PreviewKind kind;

  /// The text shown: the prompt's own text, or the sample value.
  final String text;
  final AiVariable? variable;
}

/// Splits [body] into the pieces of the preview. [sample] gives the value a
/// variable shows (always sample data, never the playing song).
List<PreviewSegment> buildPreview(
  String body,
  TemplateAnalysis analysis,
  String Function(AiVariable variable) sample,
) {
  final out = <PreviewSegment>[];
  var at = 0;
  for (final span in analysis.spans) {
    if (span.start > at) {
      out.add(PreviewSegment(PreviewKind.text, body.substring(at, span.start)));
    }
    final v = span.variable;
    out.add(switch (span.kind) {
      TemplateSpanKind.unknown => PreviewSegment(
        PreviewKind.unknown,
        body.substring(span.start, span.end),
      ),
      TemplateSpanKind.groupOff => PreviewSegment(
        PreviewKind.off,
        sample(v!),
        v,
      ),
      TemplateSpanKind.ok => PreviewSegment(
        v == AiVariable.input ? PreviewKind.input : PreviewKind.value,
        sample(v!),
        v,
      ),
    });
    at = span.end;
  }
  if (at < body.length) {
    out.add(PreviewSegment(PreviewKind.text, body.substring(at)));
  }
  return out;
}
