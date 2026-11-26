import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../conversation/parts.dart';
import '../permission.dart';
import '../settings/tool_groups.dart';
import '../tools/ai_tool.dart';

/// How long a confirmation card stays valid when the user does not answer.
const pendingCardLifetime = Duration(hours: 24);

/// Whether a card created at [createdAt] is too old to be answered.
bool cardExpired(DateTime createdAt, DateTime now) =>
    now.difference(createdAt) >= pendingCardLifetime;

/// The plugin install and model a round was made with, or the ones the
/// conversation has now.
class RoundBinding {
  const RoundBinding({
    required this.installId,
    required this.installGeneration,
    required this.model,
  });

  final String? installId;
  final int? installGeneration;
  final String? model;

  @override
  bool operator ==(Object other) =>
      other is RoundBinding &&
      other.installId == installId &&
      other.installGeneration == installGeneration &&
      other.model == model;

  @override
  int get hashCode => Object.hash(installId, installGeneration, model);
}

/// Why a call may not run now.
enum ExecRefusal {
  unknownTool('the tool does not exist'),
  external('external tools never run unasked'),
  readOnly('the chat is read-only'),
  groupOff('the tool group is turned off'),
  pluginChanged('the plugin changed'),
  modelChanged('the model changed'),
  hashMismatch('the call changed after it was allowed');

  const ExecRefusal(this.text);

  /// A short English phrase for the result the model reads.
  final String text;

  /// The reason stored in the denied card.
  String get code => name;
}

sealed class ExecDecision {
  const ExecDecision();
}

final class ExecAllowed extends ExecDecision {
  const ExecAllowed();
}

final class ExecRefused extends ExecDecision {
  const ExecRefused(this.reason);

  final ExecRefusal reason;
}

/// The gate right before a call goes `allowed -> running` (reads too).
///
/// Checks the permission the chat has now (no write in `readOnly`), the
/// switch of the tool's group, that the plugin install and the model are the
/// ones the round was made with ([round] against [current]; [current] is null
/// when the plugin is gone), and, for a call the user allowed, that it is
/// still the call they saw ([approvedHash] from [callHash]).
ExecDecision mayExecute({
  required ToolCallPart call,
  required AiTool? tool,
  required AiPermission permission,
  required bool Function(AiToolGroup group) groupEnabled,
  required RoundBinding round,
  required RoundBinding? current,
  String? approvedHash,
}) {
  if (tool == null) return const ExecRefused(ExecRefusal.unknownTool);
  if (tool.risk == ToolRisk.external) {
    return const ExecRefused(ExecRefusal.external);
  }
  if (tool.risk == ToolRisk.write && permission == AiPermission.readOnly) {
    return const ExecRefused(ExecRefusal.readOnly);
  }
  if (!groupEnabled(tool.group)) {
    return const ExecRefused(ExecRefusal.groupOff);
  }
  if (current == null ||
      current.installId != round.installId ||
      current.installGeneration != round.installGeneration) {
    return const ExecRefused(ExecRefusal.pluginChanged);
  }
  if (current.model != round.model) {
    return const ExecRefused(ExecRefusal.modelChanged);
  }
  if (approvedHash != null && approvedHash != callHash(call)) {
    return const ExecRefused(ExecRefusal.hashMismatch);
  }
  return const ExecAllowed();
}

/// A hash of the call's name and arguments (keys sorted, so the same call
/// always gives the same hash). A call with unparsed arguments hashes its
/// raw text.
String callHash(ToolCallPart call) {
  final args = call.args;
  final body = args != null ? _canonical(args) : 'raw:${call.rawArgs}';
  return sha256.convert(utf8.encode('${call.name}\n$body')).toString();
}

String _canonical(Object? v) => jsonEncode(_sorted(v));

Object? _sorted(Object? v) {
  if (v is Map) {
    final keys = v.keys.map((k) => '$k').toList()..sort();
    return {for (final k in keys) k: _sorted(v[k])};
  }
  if (v is List) return [for (final e in v) _sorted(e)];
  return v;
}

/// The answer the model reads for a call the gate refused.
String notAllowedNowText(ExecRefusal reason) =>
    'not run: not allowed now (${reason.text})';
