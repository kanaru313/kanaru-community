import '../../../plugins/domain/net/plugin_fetch_rules.dart';
import '../../domain/contract/contract_limits.dart';
import '../../domain/contract/online_output_exception.dart';
import '../../domain/contract/stream_answer.dart';
import 'output_json.dart';

/// Reads the output of `stream`: `{url, headers?, mimeType, bitrate?,
/// expiresAtMs?}`. The url and headers are checked first, so a bad url is
/// invalid whatever the type. A well-formed type this app cannot play (HLS,
/// ogg, flac) reads as [StreamUnsupported]. Throws [OnlineOutputException]
/// for a bad `url`, `headers` or `mimeType`.
StreamRead readStreamOutput(String json) {
  final data = decodeOutput(json);
  if (data is! Map) {
    throw const OnlineOutputException('stream output must be an object');
  }
  final url = _streamUrl(data['url']);
  final headers = _streamHeaders(data['headers']);
  final mimeType = data['mimeType'];
  if (mimeType is! String) {
    throw const OnlineOutputException('mimeType must be a string');
  }
  final type = mimeType.split(';').first.trim().toLowerCase();
  if (!_wellFormed.hasMatch(type)) {
    throw const OnlineOutputException('mimeType is not an audio or video type');
  }
  final container = _containers[type];
  if (container == null) return StreamUnsupported(type);
  final expiresAtMs = positiveInt(data['expiresAtMs']);
  return StreamPlayable(
    StreamAnswer(
      url: url,
      headers: Map.unmodifiable(headers),
      mimeType: mimeType,
      container: container,
      bitrate: positiveInt(data['bitrate']),
      expiresAt: expiresAtMs == null || expiresAtMs > _maxEpochMs
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresAtMs, isUtc: true),
    ),
  );
}

// The latest instant a DateTime holds.
const _maxEpochMs = 8640000000000000;

// A media type of a family that can carry audio; the HLS types are
// `application/*` or `audio/*`.
final _wellFormed = RegExp(r'^(audio|video|application)/[^/\s]+$');

// Types the player has a demuxer for. Every HLS type and anything else is
// unsupported for now.
const _containers = {
  'audio/mpeg': StreamContainer.mp3,
  'audio/mp3': StreamContainer.mp3,
  'audio/mp4': StreamContainer.mp4,
  'audio/x-m4a': StreamContainer.mp4,
  'video/mp4': StreamContainer.mp4,
  'audio/webm': StreamContainer.webm,
  'video/webm': StreamContainer.webm,
  'audio/x-matroska': StreamContainer.webm,
};

Uri _streamUrl(Object? value) {
  const problem = OnlineOutputException(
    'url must be absolute https without port or user info',
  );
  if (value is! String || tokenBytes(value) > maxTokenBytes) throw problem;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.hasPort ||
      writesPort(value) ||
      uri.userInfo.isNotEmpty) {
    throw problem;
  }
  return uri;
}

/// The headers to send: filtered like any plugin request header, then
/// without `range` and `if-range`, which the player decides.
Map<String, String> _streamHeaders(Object? value) {
  if (value == null) return const {};
  if (value is! Map || value.length > maxStreamHeaders) {
    throw const OnlineOutputException(
      'headers must be an object of at most $maxStreamHeaders strings',
    );
  }
  final requested = <(String, String)>[];
  for (final MapEntry(:key, :value) in value.entries) {
    if (key is! String || value is! String) {
      throw const OnlineOutputException('headers values must be strings');
    }
    requested.add((key, value));
  }
  final checked = pluginRequestHeaders(requested);
  if (checked == null) {
    throw const OnlineOutputException('headers has a bad name or value');
  }
  return {...checked.headers}
    ..remove('range')
    ..remove('if-range');
}
