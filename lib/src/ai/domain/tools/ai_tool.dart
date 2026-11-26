import '../conversation/track_ref_snapshot.dart';
import '../settings/tool_groups.dart';
import 'schema_validator.dart';
import 'tool_env.dart';

/// Where a tool comes from. v1 offers built-in tools only.
enum ToolSource { builtin, plugin, mcp }

/// What running a tool does. The permission gate decides on this: reads run
/// freely, writes ask in Ask mode, external tools never run unasked.
enum ToolRisk { read, write, external }

/// A tool's answer. [text] is what the model reads (JSON for the built-in
/// tools); an error is sent to the model as `Error: <text>`.
class ToolOutcome {
  const ToolOutcome.ok(this.text) : isError = false;
  const ToolOutcome.error(this.text) : isError = true;

  final String text;
  final bool isError;
}

/// What a confirm card shows before a write runs.
class ToolPreview {
  const ToolPreview({required this.summary, this.tracks = const []});

  final String summary;
  final List<TrackRefSnapshot> tracks;
}

/// One tool the assistant may call.
abstract class AiTool {
  const AiTool();

  /// The name the model calls (at most 64 characters).
  String get name;

  String get description;

  /// The privacy group whose Settings switch turns this tool on or off.
  AiToolGroup get group;

  ToolSource get source => ToolSource.builtin;

  ToolRisk get risk => ToolRisk.read;

  /// JSON Schema (the contract's subset) of the arguments object.
  Map<String, Object?> get parameters;

  /// Runs with arguments already checked against [parameters].
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env);

  /// The preview of a write for its confirm card; null for tools that need no
  /// card. Implementations validate again: the library may have changed since
  /// the model chose its arguments.
  Future<ToolPreview?> describe(Map<String, Object?> args, ToolEnv env) async =>
      null;

  /// Validates [args], then runs. A schema failure or a thrown error becomes
  /// an error outcome; nothing escapes to the loop.
  Future<ToolOutcome> run(Map<String, Object?> args, ToolEnv env) async {
    final problem = validateAgainstSchema(parameters, args);
    if (problem != null) {
      return ToolOutcome.error('invalid arguments: $problem');
    }
    try {
      return await call(args, env);
    } on Object catch (e) {
      // The message of an arbitrary exception may carry paths or SQL; the
      // model only needs to know that it failed.
      return ToolOutcome.error('tool failed (${e.runtimeType})');
    }
  }

  /// The `tools[]` entry of the chat contract.
  Map<String, Object?> toWire() => {
    'name': name,
    'description': description,
    'parameters': parameters,
  };
}
