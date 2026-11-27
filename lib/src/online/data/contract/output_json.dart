import 'dart:convert';

import '../../domain/contract/contract_limits.dart';
import '../../domain/contract/link_port.dart';
import '../../domain/contract/online_output_exception.dart';

/// The decoded output JSON of a streaming script. Throws
/// [OnlineOutputException] when it is not JSON.
Object? decodeOutput(String json) {
  try {
    return jsonDecode(json);
  } on FormatException {
    throw const OnlineOutputException('output is not JSON');
  }
}

final _notPrintableAscii = RegExp(r'[^\x21-\x7e]');

/// [value] as an integer above 0 (a whole double such as `5.0` counts), else
/// null.
int? positiveInt(Object? value) {
  final int number;
  if (value is int) {
    number = value;
  } else if (value is double &&
      value.isFinite &&
      value == value.truncate() &&
      value.abs() < 9007199254740992.0) {
    number = value.toInt();
  } else {
    return null;
  }
  return number > 0 ? number : null;
}

/// The UTF-8 length of [text], or its UTF-16 length when that cannot pass
/// [maxTokenBytes] either way (cheaper, same verdict).
int tokenBytes(String text) {
  // A UTF-16 unit is at least one byte and at most three.
  if (text.length * 3 <= maxTokenBytes) return text.length;
  return utf8.encode(text).length;
}

/// [value] when it is an absolute `https` URL of at most [maxLinkChars]
/// characters without user info or a written port; else null. Only printable
/// ASCII is accepted (no space, control or non-ASCII character): a link must
/// arrive already percent-encoded, so what is stored is what was sent.
String? httpsLink(Object? value) {
  if (value is! String ||
      value.length > maxLinkChars ||
      _notPrintableAscii.hasMatch(value)) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      writesPort(value)) {
    return null;
  }
  return value;
}
