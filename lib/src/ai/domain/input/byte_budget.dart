import 'dart:convert';

/// Largest request the app sends: UTF-8 bytes of `jsonEncode(input)`. The
/// runtime refuses bodies over 1 MiB; the rest is left for the plugin's own
/// wrapping.
const chatMaxInputBytes = 768 * 1024;

/// Bytes counted per token of context window, and the share of the window the
/// input may fill. Input plus the reserved output must fit the model.
const chatBytesPerToken = 2;
const chatContextShare = 0.75;

/// The input limit of a model: the smaller of [chatMaxInputBytes] and
/// `context × 2 bytes × 0.75 − maxOutputTokens × 2 bytes` (the reserved reply
/// is counted in bytes like the input). Never below 0.
int chatInputByteLimit({required int context, int? maxOutputTokens}) {
  final tokenBudget =
      (context * chatBytesPerToken * chatContextShare).floor() -
      (maxOutputTokens ?? 0) * chatBytesPerToken;
  final limit = tokenBudget < chatMaxInputBytes
      ? tokenBudget
      : chatMaxInputBytes;
  return limit < 0 ? 0 : limit;
}

/// UTF-8 bytes of the JSON text of [value] (what is sent).
int jsonByteLength(Object? value) => utf8.encode(jsonEncode(value)).length;
