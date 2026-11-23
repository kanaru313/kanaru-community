/// The `kind` of a run that did not fail but printed to the console.
const runLogKindOk = 'ok';

/// The `kind` of a caller's refusal of a run's output.
const runLogKindInvalidResponse = 'invalidResponse';

/// One request of a run as the log keeps it: no query string, header or body,
/// so nothing a script sent can be in it.
class RunLogRequest {
  const RunLogRequest({
    required this.method,
    required this.host,
    required this.path,
    required this.status,
    required this.ms,
    this.blocked = false,
  });

  final String method;
  final String host;

  /// The path only (no query string, no fragment).
  final String path;

  /// The HTTP status; null when no answer came (refused, failed, abandoned).
  final int? status;
  final int ms;

  /// The request was refused as a blocked address. Never written to the file:
  /// the app log names the host of such a request.
  final bool blocked;

  RunLogRequest copyWith({String? host, String? path}) => RunLogRequest(
    method: method,
    host: host ?? this.host,
    path: path ?? this.path,
    status: status,
    ms: ms,
    blocked: blocked,
  );

  Map<String, Object?> toJson() => {
    'method': method,
    'host': host,
    'path': path,
    'status': status,
    'ms': ms,
  };

  static RunLogRequest? fromJson(Object? json) {
    if (json is! Map) return null;
    final status = json['status'];
    final ms = json['ms'];
    return RunLogRequest(
      method: json['method'] is String ? json['method'] as String : '',
      host: json['host'] is String ? json['host'] as String : '',
      path: json['path'] is String ? json['path'] as String : '',
      status: status is int ? status : null,
      ms: ms is int ? ms : 0,
    );
  }
}

/// One line of a plugin's run log. `query` is the run input of a lyrics
/// script (song data included; the file stays on this device and is deleted
/// with the plugin); it is null for every other script.
class RunLogEvent {
  const RunLogEvent({
    required this.time,
    required this.installId,
    required this.pluginName,
    required this.version,
    required this.script,
    this.query,
    required this.kind,
    this.message,
    this.stack,
    this.console = const [],
    this.requests = const [],
  });

  final DateTime time;
  final String installId;
  final String pluginName;
  final String version;
  final String script;
  final Object? query;

  /// A failure name (`timeout`, `auth`, `invalidResponse`, ...) or
  /// [runLogKindOk].
  final String kind;
  final String? message;
  final String? stack;
  final List<String> console;
  final List<RunLogRequest> requests;

  /// Whether the run failed (an `ok` event only carries console output).
  bool get isFailure => kind != runLogKindOk;

  Map<String, Object?> toJson() => {
    'ts': time.toUtc().toIso8601String(),
    'installId': installId,
    'pluginName': pluginName,
    'version': version,
    'script': script,
    'query': query,
    'kind': kind,
    'message': message,
    'stack': stack,
    'console': console,
    'requests': [for (final r in requests) r.toJson()],
  };

  /// The event of a log [line]; null for a line that is not one (corrupt,
  /// cut short, written by something else). Fields of a wrong type fall back
  /// to empty; only the time and the kind are required.
  static RunLogEvent? tryParse(Object? json) {
    if (json is! Map) return null;
    final ts = json['ts'] is String ? DateTime.tryParse(json['ts']) : null;
    final kind = json['kind'];
    if (ts == null || kind is! String || kind.isEmpty) return null;
    String text(String key) => json[key] is String ? json[key] as String : '';
    final console = json['console'];
    final requests = json['requests'];
    return RunLogEvent(
      time: ts,
      installId: text('installId'),
      pluginName: text('pluginName'),
      version: text('version'),
      script: text('script'),
      query: json['query'],
      kind: kind,
      message: json['message'] is String ? json['message'] as String : null,
      stack: json['stack'] is String ? json['stack'] as String : null,
      console: console is List ? [...console.whereType<String>()] : const [],
      requests: requests is List
          ? [for (final r in requests) ?RunLogRequest.fromJson(r)]
          : const [],
    );
  }
}
