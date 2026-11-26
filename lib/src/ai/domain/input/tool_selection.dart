import '../permission.dart';
import '../settings/tool_groups.dart';
import '../tools/ai_tool.dart';
import '../tools/ai_tool_registry.dart';

/// The tools one request offers. A tool is offered when:
///
/// - the model can use tools at all ([modelSupportsTools]),
/// - its group's Settings switch is on ([groupEnabled]),
/// - it is not a write in a read-only conversation, and it is not an
///   external tool (those never run unasked in v1).
///
/// The final round offers the same list (with `toolChoice: "none"`), so the
/// cache of the provider and the history stay consistent.
List<AiTool> offeredTools(
  AiToolRegistry registry, {
  required AiPermission permission,
  required bool Function(AiToolGroup group) groupEnabled,
  required bool modelSupportsTools,
}) {
  if (!modelSupportsTools) return const [];
  return registry.where((tool) {
    if (!groupEnabled(tool.group)) return false;
    if (tool.risk == ToolRisk.external) return false;
    if (tool.risk == ToolRisk.write && permission == AiPermission.readOnly) {
      return false;
    }
    return true;
  });
}
