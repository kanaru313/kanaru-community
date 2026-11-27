import 'track_ref_snapshot.dart';

/// One piece of a message. Stored as JSON by `parts_codec.dart`; a part type
/// this build does not know survives as [UnknownPart], so a newer build's
/// data is never lost or rewritten by an older one.
sealed class AiPart {
  const AiPart();
}

/// What a [DataPart] carries (the `source` of the chat contract).
enum DataSource {
  lyrics('lyrics'),
  queue('queue'),
  nowPlaying('now_playing'),
  track('track'),
  album('album'),
  artist('artist'),
  genre('genre'),
  language('language'),
  playlist('playlist'),
  input('input');

  const DataSource(this.wire);

  final String wire;

  static DataSource? fromWire(Object? raw) {
    for (final v in values) {
      if (v.wire == raw) return v;
    }
    return null;
  }
}

/// Words written by the user or the model.
class TextPart extends AiPart {
  const TextPart(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is TextPart && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// Untrusted data the app attached (a variable, a chip, a tool value). The
/// model gets it fenced, never as instructions.
class DataPart extends AiPart {
  const DataPart({required this.source, required this.text});

  final DataSource source;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is DataPart && other.source == source && other.text == text;

  @override
  int get hashCode => Object.hash(source, text);
}

/// The model asked for a tool. Exactly one of [args] (parsed) and [rawArgs]
/// (the model's text, which did not parse) is set.
class ToolCallPart extends AiPart {
  const ToolCallPart.parsed({
    required this.id,
    required this.name,
    required Map<String, Object?> this.args,
    this.providerId,
  }) : rawArgs = null;

  const ToolCallPart.raw({
    required this.id,
    required this.name,
    required String this.rawArgs,
    this.providerId,
  }) : args = null;

  /// The app's id of the call; the result carries the same one.
  final String id;

  /// The provider's own id of the call, when it has one.
  final String? providerId;
  final String name;
  final Map<String, Object?>? args;
  final String? rawArgs;

  @override
  bool operator ==(Object other) =>
      other is ToolCallPart &&
      other.id == id &&
      other.providerId == providerId &&
      other.name == name &&
      other.rawArgs == rawArgs &&
      _jsonEquals(other.args, args);

  @override
  int get hashCode => Object.hash(id, providerId, name, rawArgs);
}

/// What a tool answered. [content] holds [TextPart]s and [DataPart]s.
class ToolResultPart extends AiPart {
  const ToolResultPart({
    required this.id,
    required this.name,
    required this.content,
    this.providerId,
    this.isError = false,
  });

  final String id;
  final String? providerId;
  final String name;
  final List<AiPart> content;
  final bool isError;

  @override
  bool operator ==(Object other) =>
      other is ToolResultPart &&
      other.id == id &&
      other.providerId == providerId &&
      other.name == name &&
      other.isError == isError &&
      _jsonEquals(other.content, content);

  @override
  int get hashCode => Object.hash(id, providerId, name, isError);
}

/// Where a confirmation card stands.
enum ConfirmStatus {
  pending,
  allowed,
  denied,

  /// The user sent a new message instead of answering.
  deniedByNewMessage,

  /// The card was left over when the app closed or the turn moved on.
  expired,
}

/// The card that asks the user to allow a write tool call.
class ConfirmPart extends AiPart {
  const ConfirmPart({
    required this.callId,
    required this.status,
    this.reason,
    this.approvalHash,
  });

  /// The [ToolCallPart.id] the card is about.
  final String callId;
  final ConfirmStatus status;

  /// Why it was denied (a short code), only with [ConfirmStatus.denied].
  final String? reason;

  /// Hash of the call (name and arguments) the user saw when they allowed
  /// it; only with [ConfirmStatus.allowed]. Stored with the card so the
  /// check before the call runs survives a restart.
  final String? approvalHash;

  @override
  bool operator ==(Object other) =>
      other is ConfirmPart &&
      other.callId == callId &&
      other.status == status &&
      other.reason == reason &&
      other.approvalHash == approvalHash;

  @override
  int get hashCode => Object.hash(callId, status, reason, approvalHash);
}

/// The queue a tool replaced, enough to offer "play the old queue again".
class ReplacedQueueSnapshot {
  const ReplacedQueueSnapshot({
    required this.tracks,
    required this.userOrder,
    required this.shuffled,
    this.previousIndex,
  });

  /// Track ids in play order (shuffled order when [shuffled]).
  final List<int> tracks;

  /// The same tracks in the order the user built.
  final List<int> userOrder;
  final bool shuffled;

  /// Position of the playing entry in [tracks]; null when nothing was loaded.
  final int? previousIndex;

  @override
  bool operator ==(Object other) =>
      other is ReplacedQueueSnapshot &&
      other.shuffled == shuffled &&
      other.previousIndex == previousIndex &&
      _jsonEquals(other.tracks, tracks) &&
      _jsonEquals(other.userOrder, userOrder);

  @override
  int get hashCode => Object.hash(shuffled, previousIndex, tracks.length);
}

/// The outcome of a write tool, built from what the API returned.
class DonePart extends AiPart {
  const DonePart({
    required this.callId,
    this.added = const [],
    this.removed = const [],
    this.absent = const [],
    this.replacedQueue,
  });

  final String callId;
  final List<TrackRefSnapshot> added;
  final List<TrackRefSnapshot> removed;

  /// Ids the tool was given that are not visible tracks (never written).
  final List<int> absent;
  final ReplacedQueueSnapshot? replacedQueue;

  @override
  bool operator ==(Object other) =>
      other is DonePart &&
      other.callId == callId &&
      other.replacedQueue == replacedQueue &&
      _jsonEquals(other.added, added) &&
      _jsonEquals(other.removed, removed) &&
      _jsonEquals(other.absent, absent);

  @override
  int get hashCode => Object.hash(callId, added.length, removed.length);
}

/// A turn that ended in an error. Holds the contract's code and kind only,
/// never provider text.
class ErrorPart extends AiPart {
  const ErrorPart({required this.code, required this.kind, this.retryAt});

  final String code;
  final String kind;

  /// When a retry is allowed (rate limit), if the provider said.
  final DateTime? retryAt;

  @override
  bool operator ==(Object other) =>
      other is ErrorPart &&
      other.code == code &&
      other.kind == kind &&
      other.retryAt == retryAt;

  @override
  int get hashCode => Object.hash(code, kind, retryAt);
}

/// A line the app writes into the transcript itself.
class EventPart extends AiPart {
  const EventPart.pluginSwitch({required this.fromName, required this.toName});

  /// Display names of the plugin the chat left and the one it moved to.
  final String fromName;
  final String toName;

  @override
  bool operator ==(Object other) =>
      other is EventPart &&
      other.fromName == fromName &&
      other.toName == toName;

  @override
  int get hashCode => Object.hash(fromName, toName);
}

/// What a [ChipPart] points at.
enum ChipKind {
  nowPlaying,
  song,
  songs,
  album,
  artist,
  genre,
  language,
  playlist,
}

/// A chip the user attached to a message ("this song", "this playlist").
class ChipPart extends AiPart {
  const ChipPart({
    required this.kind,
    this.ref,
    this.label,
    this.tracks = const [],
  });

  final ChipKind kind;

  /// The key of the thing: a playlist id, an album / artist / genre /
  /// language key; null for [ChipKind.nowPlaying], [ChipKind.song] and
  /// [ChipKind.songs] (those use [tracks]).
  final String? ref;

  /// Text the chip shows. For a songs chip whose ids were cut it holds the
  /// real selection size as a number (read only through `songsChipTotal`);
  /// a typed field would change this persisted shape, so it is a follow-up.
  final String? label;

  /// The tracks of a song or songs chip.
  final List<TrackRefSnapshot> tracks;

  @override
  bool operator ==(Object other) =>
      other is ChipPart &&
      other.kind == kind &&
      other.ref == ref &&
      other.label == label &&
      _jsonEquals(other.tracks, tracks);

  @override
  int get hashCode => Object.hash(kind, ref, label, tracks.length);
}

/// A part this build cannot read (a newer type, or a known type with a shape
/// it does not understand). [json] is written back unchanged.
class UnknownPart extends AiPart {
  const UnknownPart(this.json);

  final Map<String, Object?> json;

  /// The `t` of the stored part, or null when it had none.
  String? get type => json['t'] is String ? json['t'] as String : null;

  @override
  bool operator ==(Object other) =>
      other is UnknownPart && _jsonEquals(other.json, json);

  @override
  int get hashCode => json.length.hashCode;
}

/// Structural equality for the JSON-shaped values parts hold (lists, maps,
/// scalars and parts).
bool _jsonEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_jsonEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_jsonEquals(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}
