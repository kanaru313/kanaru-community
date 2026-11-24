import 'dart:convert';

import '../../../plugins/domain/package/text_clean.dart';
import 'translation_language.dart';

/// The result of checking one answer: a [TranslateChunk] or a rejection.
sealed class TranslateOutput {
  const TranslateOutput();
}

/// A checked answer for one chunk.
class TranslateChunk extends TranslateOutput {
  const TranslateChunk({
    required this.texts,
    required this.detected,
    required this.isEcho,
  });

  /// Sent line → cleaned translation.
  final Map<String, String> texts;

  /// Sent line → language the plugin saw (`null` when none or dropped).
  final Map<String, String?> detected;

  /// Every text equals its source: the service passed the lines through.
  final bool isEcho;
}

/// An answer that broke the output rules. [reason] is a fixed short text with
/// no lyric content, safe for the plugin's rejected-output log.
class TranslateRejected extends TranslateOutput {
  const TranslateRejected(this.reason);

  final String reason;
}

// A BCP 47 style tag: `en`, `pt-BR`, `zh-Hant-TW`.
final _languageTag = RegExp(r'^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8}){0,3}$');
final _newlines = RegExp(r'[\r\n\u0085  ]+');
final _tabs = RegExp(r'\t+');

/// Reads the output of a `translate` run for [sent] (the lines that were
/// sent) toward [to]. Returns a [TranslateChunk] or a [TranslateRejected];
/// never throws, whatever [json] holds.
///
/// Rules: a JSON array with one object per sent line, each with a string
/// `text` of at most `4 x source length + 200` characters; controls and bidi
/// marks are stripped and newlines become one space; more than half of the
/// non-blank sources coming back empty is a rejection; `detected` is kept
/// only as a language tag, and dropped when it names [to] on a changed line.
TranslateOutput readTranslateOutput(
  String json,
  List<String> sent, {
  String to = '',
}) {
  final Object? data;
  try {
    data = jsonDecode(json);
  } catch (_) {
    return const TranslateRejected('not valid JSON');
  }
  if (data is! List) return const TranslateRejected('not an array');
  if (data.length != sent.length) {
    return const TranslateRejected('wrong item count');
  }
  final texts = <String, String>{};
  final detected = <String, String?>{};
  var nonBlank = 0;
  var empty = 0;
  var echo = sent.isNotEmpty;
  for (var i = 0; i < data.length; i++) {
    final item = data[i];
    final text = item is Map ? item['text'] : null;
    if (text is! String) return const TranslateRejected('item without text');
    final clean = cleanText(
      text.replaceAll(_newlines, ' ').replaceAll(_tabs, ' '),
    );
    final source = sent[i];
    if (clean.length > 4 * source.length + 200) {
      return const TranslateRejected('text too long');
    }
    if (source.trim().isNotEmpty) {
      nonBlank++;
      if (clean.isEmpty) empty++;
    }
    var code = (item as Map)['detected']; // item is a Map: text was read
    if (code is! String || !_languageTag.hasMatch(code)) code = null;
    if (code != null &&
        to.isNotEmpty &&
        sameLanguage(code as String, to) &&
        clean != source.trim()) {
      code = null;
    }
    if (clean != source.trim()) echo = false;
    texts[source] = clean;
    detected[source] = code as String?;
  }
  if (empty * 2 > nonBlank) return const TranslateRejected('mostly empty');
  return TranslateChunk(texts: texts, detected: detected, isEcho: echo);
}
