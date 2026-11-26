import '../conversation/parts.dart';
import '../input/history_turns.dart' show fenceSafe;

export '../input/system_prompt.dart' show newChatBoundary;

/// Cleans [text] for the model: C0/C1 controls, bidi and zero-width
/// characters go, and every `<data` / `</data` is broken so the value cannot
/// close or fake the fence the plugin draws around it. The input builder
/// applies the same rule again on the way out; this is the stored form.
String fenceText(String text) => fenceSafe(text);

/// A fenced data part: untrusted [text] of [source], never a [TextPart].
DataPart fencedData(DataSource source, String text) =>
    DataPart(source: source, text: fenceText(text));
