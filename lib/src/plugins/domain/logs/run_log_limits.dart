import 'dart:convert';

import 'run_log_event.dart';

/// Size caps of one log line, so a chatty or hostile script cannot fill a
/// plugin's file with a single event (the worst line stays near 300 KB, under
/// the file's rotation size).
const _maxMessage = 4000;
const _maxStack = 8000;
const _maxConsoleLines = 50;
const _maxConsoleLine = 500;
const _maxRequests = 100;
const _maxQueryText = 8000;

String _cut(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max)}…';

/// [event] with every field cut to its cap. Call after redaction: a cut never
/// leaves a piece of a secret that redaction would have missed.
RunLogEvent capRunLogEvent(RunLogEvent event) {
  final query = event.query;
  Object? cappedQuery = query;
  if (query != null) {
    final text = jsonEncode(query);
    if (text.length > _maxQueryText) cappedQuery = _cut(text, _maxQueryText);
  }
  return RunLogEvent(
    time: event.time,
    installId: event.installId,
    pluginName: event.pluginName,
    version: event.version,
    script: event.script,
    query: cappedQuery,
    kind: event.kind,
    message: event.message == null ? null : _cut(event.message!, _maxMessage),
    stack: event.stack == null ? null : _cut(event.stack!, _maxStack),
    console: [
      for (final line in event.console.take(_maxConsoleLines))
        _cut(line, _maxConsoleLine),
    ],
    requests: event.requests.take(_maxRequests).toList(),
  );
}
