import '../../../plugins/domain/package/text_clean.dart';
import '../../domain/contract/contract_limits.dart';
import '../../domain/contract/online_output_exception.dart';
import 'output_json.dart';

/// Reads the output of `autocomplete`: an array of strings. Non-strings,
/// empty or over-long entries and repeats are skipped; the first
/// [maxSuggestions] are kept. Throws [OnlineOutputException] when the output
/// is not an array.
List<String> readAutocompleteOutput(String json) {
  final data = decodeOutput(json);
  if (data is! List) {
    throw const OnlineOutputException('autocomplete output must be an array');
  }
  final out = <String>[];
  for (final entry in data) {
    if (out.length >= maxSuggestions) break;
    if (entry is! String) continue;
    final text = cleanText(entry);
    if (text.isEmpty ||
        text.runes.length > maxSuggestionRunes ||
        out.contains(text)) {
      continue;
    }
    out.add(text);
  }
  return List.unmodifiable(out);
}
