import 'dart:convert';

import 'parts.dart';
import 'track_ref_snapshot.dart';

/// Version of the stored parts JSON this build reads and writes.
const int partsJsonVersion = 1;

/// Why a stored parts text could not be read at all.
sealed class AiPartsException implements Exception {
  const AiPartsException(this.message);

  final String message;

  @override
  String toString() => 'AiPartsException: $message';
}

/// The text is from a newer (or unknown) format: refused, never guessed.
class UnsupportedPartsVersion extends AiPartsException {
  UnsupportedPartsVersion(this.version)
    : super('parts version $version is not supported');

  final Object? version;
}

/// The text is not the `{"v":…,"parts":[…]}` shape.
class MalformedParts extends AiPartsException {
  const MalformedParts(super.message);
}

/// `{"v":1,"parts":[…]}` text for [parts].
String encodeParts(List<AiPart> parts) => jsonEncode({
  'v': partsJsonVersion,
  'parts': [for (final p in parts) partToJson(p)],
});

/// The parts of [text]. Throws [UnsupportedPartsVersion] for another version
/// and [MalformedParts] when the text is not the expected shape. A single
/// part that is unknown or damaged becomes an [UnknownPart] and keeps its
/// JSON.
List<AiPart> decodeParts(String text) {
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException catch (e) {
    throw MalformedParts('not JSON: ${e.message}');
  }
  if (root is! Map<String, Object?>) {
    throw const MalformedParts('parts text is not an object');
  }
  final version = root['v'];
  if (version != partsJsonVersion) throw UnsupportedPartsVersion(version);
  final list = root['parts'];
  if (list is! List<Object?>) {
    throw const MalformedParts('parts is not a list');
  }
  return partsFromJsonList(list);
}

/// Parts from a decoded JSON list (also the `content` of a tool result).
List<AiPart> partsFromJsonList(List<Object?> list) => [
  for (final item in list) partFromJson(item),
];

/// The JSON of one part.
Map<String, Object?> partToJson(AiPart part) => switch (part) {
  TextPart(:final text) => {'t': 'text', 'text': text},
  DataPart(:final source, :final text) => {
    't': 'data',
    'source': source.wire,
    'text': text,
  },
  ToolCallPart() => {
    't': 'tool_call',
    'id': part.id,
    if (part.providerId != null) 'providerId': part.providerId,
    'name': part.name,
    if (part.args != null) 'args': part.args,
    if (part.rawArgs != null) 'rawArgs': part.rawArgs,
  },
  ToolResultPart() => {
    't': 'tool_result',
    'id': part.id,
    if (part.providerId != null) 'providerId': part.providerId,
    'name': part.name,
    'content': [for (final p in part.content) partToJson(p)],
    'isError': part.isError,
  },
  ConfirmPart() => {
    't': 'confirm',
    'callId': part.callId,
    'status': part.status.name,
    if (part.reason != null) 'reason': part.reason,
    if (part.approvalHash != null) 'approvalHash': part.approvalHash,
  },
  DonePart() => {
    't': 'done',
    'callId': part.callId,
    'added': [for (final t in part.added) t.toJson()],
    'removed': [for (final t in part.removed) t.toJson()],
    'absent': part.absent,
    if (part.replacedQueue case final q?)
      'replacedQueue': {
        'tracks': q.tracks,
        'userOrder': q.userOrder,
        'shuffled': q.shuffled,
        if (q.previousIndex != null) 'previousIndex': q.previousIndex,
      },
  },
  ErrorPart() => {
    't': 'error',
    'code': part.code,
    'kind': part.kind,
    if (part.retryAt != null) 'retryAt': part.retryAt!.millisecondsSinceEpoch,
  },
  EventPart() => {
    't': 'event',
    'event': 'plugin_switch',
    'from': part.fromName,
    'to': part.toName,
  },
  ChipPart() => {
    't': 'chip',
    'kind': part.kind.name,
    if (part.ref != null) 'ref': part.ref,
    if (part.label != null) 'label': part.label,
    if (part.tracks.isNotEmpty)
      'tracks': [for (final t in part.tracks) t.toJson()],
  },
  UnknownPart(:final json) => json,
};

/// One part from decoded JSON; anything not understood is an [UnknownPart].
AiPart partFromJson(Object? json) {
  if (json is! Map<String, Object?>) {
    return UnknownPart({'t': 'invalid', 'value': json});
  }
  try {
    return _known(json) ?? UnknownPart(json);
  } on FormatException {
    return UnknownPart(json);
  }
}

AiPart? _known(Map<String, Object?> j) {
  switch (j['t']) {
    case 'text':
      return TextPart(_str(j, 'text'));
    case 'data':
      final source = DataSource.fromWire(j['source']);
      if (source == null) return null;
      return DataPart(source: source, text: _str(j, 'text'));
    case 'tool_call':
      final args = j['args'];
      final raw = j['rawArgs'];
      final id = _str(j, 'id');
      final name = _str(j, 'name');
      final providerId = _optStr(j, 'providerId');
      if (args is Map<String, Object?> && raw == null) {
        return ToolCallPart.parsed(
          id: id,
          name: name,
          args: args,
          providerId: providerId,
        );
      }
      if (raw is String && args == null) {
        return ToolCallPart.raw(
          id: id,
          name: name,
          rawArgs: raw,
          providerId: providerId,
        );
      }
      return null;
    case 'tool_result':
      final content = j['content'];
      if (content is! List<Object?>) return null;
      return ToolResultPart(
        id: _str(j, 'id'),
        providerId: _optStr(j, 'providerId'),
        name: _str(j, 'name'),
        content: partsFromJsonList(content),
        isError: j['isError'] == true,
      );
    case 'confirm':
      final status = _byName(ConfirmStatus.values, j['status']);
      if (status == null) return null;
      return ConfirmPart(
        callId: _str(j, 'callId'),
        status: status,
        reason: _optStr(j, 'reason'),
        approvalHash: _optStr(j, 'approvalHash'),
      );
    case 'done':
      return DonePart(
        callId: _str(j, 'callId'),
        added: _snapshots(j['added']),
        removed: _snapshots(j['removed']),
        absent: _ints(j['absent']),
        replacedQueue: _replaced(j['replacedQueue']),
      );
    case 'error':
      final at = j['retryAt'];
      if (at != null && at is! int) return null;
      return ErrorPart(
        code: _str(j, 'code'),
        kind: _str(j, 'kind'),
        retryAt: at == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(at as int),
      );
    case 'event':
      if (j['event'] != 'plugin_switch') return null;
      return EventPart.pluginSwitch(
        fromName: _str(j, 'from'),
        toName: _str(j, 'to'),
      );
    case 'chip':
      final kind = _byName(ChipKind.values, j['kind']);
      if (kind == null) return null;
      return ChipPart(
        kind: kind,
        ref: _optStr(j, 'ref'),
        label: _optStr(j, 'label'),
        tracks: _snapshots(j['tracks']),
      );
  }
  return null;
}

String _str(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is String) return v;
  throw FormatException('$key is not a string');
}

String? _optStr(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v == null || v is String) return v as String?;
  throw FormatException('$key is not a string');
}

T? _byName<T extends Enum>(List<T> values, Object? raw) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

List<TrackRefSnapshot> _snapshots(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List<Object?>) throw const FormatException('not a list');
  return [for (final e in raw) TrackRefSnapshot.fromJson(e)];
}

List<int> _ints(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List<Object?>) throw const FormatException('not a list');
  return [
    for (final e in raw)
      if (e is int) e else throw const FormatException('not an int'),
  ];
}

ReplacedQueueSnapshot? _replaced(Object? raw) {
  if (raw == null) return null;
  if (raw is! Map<String, Object?>) {
    throw const FormatException('not an object');
  }
  final index = raw['previousIndex'];
  if (index != null && index is! int) throw const FormatException('bad index');
  return ReplacedQueueSnapshot(
    tracks: _ints(raw['tracks']),
    userOrder: _ints(raw['userOrder']),
    shuffled: raw['shuffled'] == true,
    previousIndex: index as int?,
  );
}
