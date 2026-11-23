import 'dart:convert';

import '../config/config_field.dart';
import 'run_log_event.dart';

/// What replaces a hidden value.
const redactionMask = '***';

/// What replaces a path segment that looks like a token.
const _segmentMask = '…';

/// Shortest user-entered config value that is hidden (shorter ones would
/// blank ordinary words of a message).
const _minConfigLength = 4;

/// Shortest value of the other sources (storage, headers, run input, tokens of
/// a multi-value setting) that is hidden.
const _minOtherLength = 8;

/// Shortest path segment of token characters that is hidden.
const _minSegmentLength = 16;

final _tokenSplit = RegExp(r'[\s,;]+');
final _lineSplit = RegExp(r'\r?\n');
final _tokenSegment = RegExp('^[A-Za-z0-9_-]{$_minSegmentLength,}\$');

/// Hides, in the text of a run log event, the values the app knows to be
/// secret: what the user typed into the plugin's settings, what the plugin
/// keeps in its storage, text added to the settings for one run, credential
/// headers the script sent, and (for a script whose input is not logged) the
/// input itself. Token-like path segments are hidden by shape.
///
/// Best effort: a script that prints a secret in another form (base64, split
/// in two) is not caught.
class LogRedactor {
  /// [storedConfig] is the stored value of each setting by key, [schema] the
  /// manifest's fields: only values the user typed are hidden (selects and
  /// toggles stay readable; a key not in the schema is hidden). [configAppend]
  /// are the run's own additions, [storageJsons] the plugin's storage before
  /// and after the run, [headerSecrets] the credential header values the
  /// fetch handler saw, [hiddenInput] the run input when it must not be
  /// logged.
  LogRedactor({
    List<ConfigField> schema = const [],
    Map<String, Object?> storedConfig = const {},
    Iterable<String> configAppend = const [],
    Iterable<String> storageJsons = const [],
    Iterable<String> headerSecrets = const [],
    Object? hiddenInput,
  }) : _secrets = _build(
         userEnteredStrings(schema, storedConfig).followedBy(configAppend),
         storageJsons,
         headerSecrets,
         hiddenInput,
       );

  /// Longest first, so overlapping secrets are hidden whole.
  final List<String> _secrets;

  /// [text] with every known secret replaced by [redactionMask].
  String text(String text) {
    // Spans of every secret on the original text, merged, so the tail of a
    // second secret that overlaps the first is hidden too.
    final spans = <(int, int)>[];
    for (final secret in _secrets) {
      var at = text.indexOf(secret);
      while (at >= 0) {
        spans.add((at, at + secret.length));
        at = text.indexOf(secret, at + 1);
      }
    }
    if (spans.isEmpty) return text;
    spans.sort((a, b) => a.$1.compareTo(b.$1));
    final out = StringBuffer();
    var cursor = 0;
    var (start, end) = spans.first;
    void flush() {
      out
        ..write(text.substring(cursor, start))
        ..write(redactionMask);
      cursor = end;
    }

    for (final (s, e) in spans.skip(1)) {
      if (s <= end) {
        if (e > end) end = e;
      } else {
        flush();
        (start, end) = (s, e);
      }
    }
    flush();
    out.write(text.substring(cursor));
    return out.toString();
  }

  /// Every string of a JSON-like [value] through [text].
  Object? deep(Object? value) => switch (value) {
    String() => text(value),
    List() => [for (final v in value) deep(v)],
    Map() => {for (final e in value.entries) e.key: deep(e.value)},
    _ => value,
  };

  /// A request path: every segment of 16 or more token characters first (a
  /// signed path, a token in the path; before the secrets, so a short secret
  /// inside it cannot break the shape), then the known secrets.
  String path(String path) => text(
    path
        .split('/')
        .map((s) => _tokenSegment.hasMatch(s) ? _segmentMask : s)
        .join('/'),
  );

  /// [event] with every text field redacted.
  RunLogEvent apply(RunLogEvent event) => RunLogEvent(
    time: event.time,
    installId: event.installId,
    pluginName: event.pluginName,
    version: event.version,
    script: event.script,
    query: deep(event.query),
    kind: event.kind,
    message: event.message == null ? null : text(event.message!),
    stack: event.stack == null ? null : text(event.stack!),
    console: [for (final line in event.console) text(line)],
    requests: [
      for (final r in event.requests)
        r.copyWith(host: text(r.host), path: path(r.path)),
    ],
  );
}

/// The strings of the settings the user typed: input text / multiline / url
/// and number (as text), list items, map keys and values. Selects and
/// toggles are left out; a stored key that is not in [schema] is kept (hiding
/// too much is the safe side).
Iterable<String> userEnteredStrings(
  List<ConfigField> schema,
  Map<String, Object?> stored,
) sync* {
  final fields = {for (final f in schema) f.key: f};
  for (final e in stored.entries) {
    final field = fields[e.key];
    final value = e.value;
    if (field is SelectField || field is ToggleField) continue;
    if (field is InputField &&
        (field.format == InputFormat.number ||
            field.format == InputFormat.integer) &&
        value is num) {
      yield value.toString();
    } else {
      yield* _stringLeaves(value);
    }
  }
}

List<String> _build(
  Iterable<String> config,
  Iterable<String> storageJsons,
  Iterable<String> headerSecrets,
  Object? hiddenInput,
) {
  final values = <String>{};
  for (final value in config) {
    if (value.length >= _minConfigLength) values.add(value);
    values.addAll(_urlParts(value));
    for (final token in value.split(_tokenSplit)) {
      if (token.length >= _minOtherLength) values.add(token);
    }
  }
  for (final json in storageJsons) {
    for (final value in _storageStrings(json)) {
      if (value.length >= _minOtherLength) values.add(value);
    }
  }
  for (final value in headerSecrets) {
    if (value.isNotEmpty) values.add(value);
  }
  for (final value in _stringLeaves(hiddenInput, keys: false)) {
    if (value.length >= _minOtherLength) values.add(value);
    for (final line in value.split(_lineSplit)) {
      if (line.length >= _minOtherLength) values.add(line);
    }
  }
  final all = <String>{
    for (final v in values) ...[v, Uri.encodeComponent(v), Uri.encodeFull(v)],
  };
  return all.toList()..sort((a, b) => b.length.compareTo(a.length));
}

final _hostOfUrl = RegExp(r'^https?://(?:[^/?#@]*@)?([^/?#:]+)');

/// For a value that is an absolute http(s) URL: its host (as stored and
/// lowercased, the form a request record holds), its path, each path segment
/// and each query value, so a saved endpoint cannot be read back from the
/// pieces a request record keeps.
Iterable<String> _urlParts(String value) sync* {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return;
  }
  final stored = _hostOfUrl.firstMatch(value.trim())?.group(1);
  for (final host in {?stored, uri.host, uri.host.toLowerCase()}) {
    if (host.length >= _minConfigLength) yield host;
  }
  final path = uri.path;
  if (path.length >= _minConfigLength && path != '/') yield path;
  for (final segment in uri.pathSegments) {
    if (segment.length >= _minOtherLength) yield segment;
  }
  for (final v in uri.queryParameters.values) {
    if (v.length >= _minOtherLength) yield v;
  }
}

/// The string values of a storage map text; nothing for text that is empty or
/// not a JSON object.
Iterable<String> _storageStrings(String json) {
  if (json.isEmpty) return const [];
  try {
    return _stringLeaves(jsonDecode(json), keys: false);
  } on FormatException {
    return const [];
  }
}

// The strings of a JSON-like value: itself, list items, map keys (when
// [keys]) and values. Numbers and bools hold nothing to hide.
Iterable<String> _stringLeaves(Object? value, {bool keys = true}) =>
    switch (value) {
      String() => [value],
      List() => value.expand((v) => _stringLeaves(v, keys: keys)),
      Map() => [
        if (keys) ...value.keys.expand((k) => _stringLeaves(k, keys: keys)),
        ...value.values.expand((v) => _stringLeaves(v, keys: keys)),
      ],
      _ => const [],
    };
