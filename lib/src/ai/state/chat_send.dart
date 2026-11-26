import '../domain/conversation/parts.dart';
import '../domain/output/chat_readiness.dart';
import '../domain/settings/tool_groups.dart';
import '../domain/tools/tool_env.dart';
import '../domain/variables/chip_ref.dart';
import '../domain/variables/chip_resolver.dart';
import '../domain/variables/variable_catalog.dart';
import '../domain/variables/variable_filler.dart';

/// Why a message could not be built from the composer.
sealed class SendIssue {
  const SendIssue();
}

/// A `{{variable}}` the app could not fill (missing data, group off, a
/// leftover `{{input}}`).
final class VariableIssue extends SendIssue {
  const VariableIssue(this.issue);

  final FillIssue issue;
}

/// An attached chip whose data is not available now.
final class ChipUnavailable extends SendIssue {
  const ChipUnavailable(this.chip, this.reason);

  final ChipPart chip;
  final String reason;
}

/// An attached chip whose privacy group is off.
final class ChipGroupOff extends SendIssue {
  const ChipGroupOff(this.chip, this.group);

  final ChipPart chip;
  final AiToolGroup group;
}

/// What `send` did.
sealed class SendResult {
  const SendResult();
}

/// The message was stored and the turn runs; [done] completes when the turn
/// parks or ends.
final class SendSent extends SendResult {
  const SendSent(this.done, {this.userMessageId});

  final Future<void> done;
  final int? userMessageId;
}

/// Data a variable or chip needs is missing or switched off; nothing was
/// sent and the attachments stay.
final class SendMissingData extends SendResult {
  const SendMissingData(this.issues);

  final List<SendIssue> issues;
}

/// A value is over the size limit. Call `send` again with
/// `shortVersion: true` to send the short version of [variables] (the
/// "send the short version" offer); nothing was sent.
final class SendOversize extends SendResult {
  const SendOversize(this.variables);

  final List<AiVariable> variables;
}

/// The chat cannot send through its plugin now (no key, no model, removed).
final class SendBlocked extends SendResult {
  const SendBlocked(this.readiness);

  final ChatReadiness readiness;
}

/// A turn is already running; the message was dropped.
final class SendBusy extends SendResult {
  const SendBusy();
}

/// The message could not be stored.
final class SendFailed extends SendResult {
  const SendFailed();
}

/// The parts of a message ready to store, or why it cannot be built.
class PreparedMessage {
  const PreparedMessage.ok(this.parts, this.displayText) : failure = null;

  const PreparedMessage.failed(SendResult this.failure)
    : parts = const [],
      displayText = '';

  final List<AiPart> parts;

  /// The text with its variables shown as values (the title source).
  final String displayText;
  final SendResult? failure;
}

/// Resolves the chips and fills the variables of [text]. Chip parts come
/// first (each followed by its fenced data), then the user's text with its
/// variable data interleaved.
Future<PreparedMessage> prepareMessage({
  required String text,
  required List<ChipPart> chips,
  required ToolEnv env,
  required ChipScopePort scopes,
  required ToolGroupSwitches groupEnabled,
  required bool varBypass,
  required bool shortVersion,
}) async {
  final resolver = ChipResolver(
    env: env,
    scopes: scopes,
    groupEnabled: groupEnabled,
    varBypass: varBypass,
  );
  final issues = <SendIssue>[];
  final chipParts = <AiPart>[];
  for (final chip in chips) {
    final resolution = await resolver.resolve(
      ChipRef(
        kind: chip.kind,
        ref: chip.ref,
        label: chip.label,
        tracks: chip.tracks,
      ),
    );
    switch (resolution) {
      case ChipResolved(chip: final resolved, :final data):
        chipParts
          ..add(resolved)
          ..add(data);
      case ChipBlocked(:final group):
        issues.add(ChipGroupOff(chip, group));
      case ChipMissing(:final reason):
        issues.add(ChipUnavailable(chip, reason));
    }
  }
  final fill = await fillVariables(
    text: text,
    env: env,
    groupEnabled: groupEnabled,
    varBypass: varBypass,
    shortVersion: shortVersion,
  );
  switch (fill) {
    case FillBlocked(issues: final blocked):
      issues.addAll(blocked.map(VariableIssue.new));
    case FillOversize(:final variables):
      if (issues.isEmpty) {
        return PreparedMessage.failed(SendOversize(variables));
      }
    case FillDone():
      break;
  }
  if (issues.isNotEmpty) {
    return PreparedMessage.failed(SendMissingData(issues));
  }
  final done = fill as FillDone;
  return PreparedMessage.ok([...chipParts, ...done.parts], done.displayText);
}
