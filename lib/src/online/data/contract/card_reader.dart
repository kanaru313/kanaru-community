import '../../../plugins/domain/package/text_clean.dart';

import '../../domain/contract/contract_limits.dart';
import '../../domain/contract/item_ref.dart';
import '../../domain/contract/online_card.dart';
import 'output_json.dart';

final _control = RegExp(r'\p{Cc}', unicode: true);

/// The reason [id] is not a usable plugin id, or null when it is. An id is
/// handed back to the plugin untouched, so it is checked, never trimmed.
String? idProblem(Object? id) {
  if (id is! String || id.isEmpty || id.runes.length > maxIdRunes) {
    return 'id must be 1 to $maxIdRunes characters';
  }
  if (_control.hasMatch(id)) return 'id has a control character';
  // A proxy URL cannot carry them: URI parsing removes dot segments.
  if (id == '.' || id == '..') return 'id must not be "." or ".."';
  if (isUrlShapedId(id)) return 'id looks like a URL';
  if (hasUnpairedSurrogate(id)) return 'id is not valid text';
  return null;
}

/// [value] cleaned when it is a string of 1 to [max] code points, else null.
String? _text(Object? value, int max) {
  if (value is! String) return null;
  final text = cleanText(value);
  if (text.isEmpty || text.runes.length > max) return null;
  return text;
}

/// The card, or the fixed reason it is dropped. Optional fields that break a
/// rule read as absent; they never drop the card.
(OnlineCard?, String?) readCard(Object? raw) {
  if (raw is! Map) return (null, 'card must be an object');
  final OnlineCardKind kind;
  final rawKind = raw['kind'];
  if (rawKind == null) {
    kind = OnlineCardKind.track;
  } else {
    final match = OnlineCardKind.values.where((k) => k.name == rawKind);
    if (match.isEmpty) return (null, 'unknown kind');
    kind = match.first;
  }
  final id = raw['id'];
  final problem = idProblem(id);
  if (problem != null) return (null, problem);
  final title = _text(raw['title'], maxTitleRunes);
  if (title == null) {
    return (null, 'title must be 1 to $maxTitleRunes characters');
  }
  final ms = positiveInt(raw['durationMs']);
  return (
    OnlineCard(
      kind: kind,
      id: id as String,
      title: title,
      subtitle: _text(raw['subtitle'], maxSubtitleRunes),
      artist: _text(raw['artist'], maxArtistRunes),
      artists: _readArtists(raw['artists']),
      album: _readAlbum(raw),
      duration: ms == null || ms > maxDurationMs
          ? null
          : Duration(milliseconds: ms),
      artworkUrl: httpsLink(raw['artworkUrl']),
      webUrl: httpsLink(raw['webUrl']),
    ),
    null,
  );
}

List<CardRef> _readArtists(Object? raw) {
  if (raw is! List) return const [];
  final out = <CardRef>[];
  for (final entry in raw) {
    if (out.length >= maxCardArtists) break;
    if (entry is! Map) continue;
    final name = _text(entry['title'], maxArtistRunes);
    if (name == null) continue;
    final id = entry['id'];
    out.add(
      CardRef(id: idProblem(id) == null ? id as String : null, name: name),
    );
  }
  return List.unmodifiable(out);
}

CardRef? _readAlbum(Map<Object?, Object?> raw) {
  final albums = raw['albums'];
  final first = albums is List && albums.isNotEmpty && albums.first is Map
      ? albums.first as Map
      : null;
  final name =
      _text(raw['album'], maxTitleRunes) ??
      (first == null ? null : _text(first['title'], maxTitleRunes));
  if (name == null) return null;
  final id = first?['id'];
  return CardRef(id: idProblem(id) == null ? id as String : null, name: name);
}
