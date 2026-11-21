/// A script the runtime refused to compile. [message] is the engine's text
/// (not for display as is); [line] is 1-based when known.
class ScriptProblem {
  const ScriptProblem({this.line, required this.message});

  final int? line;
  final String message;
}

/// Syntax check of one script, run before a package is accepted. The
/// implementation (the Rust runtime, in the data layer) comes later; the
/// domain only knows this seam.
abstract interface class ScriptChecker {
  /// The problem with [source] (the text of the file [fileName]), or null
  /// when it compiles. Throws when the check cannot run at all (library not
  /// loadable): accepting then would claim the script valid without looking.
  Future<ScriptProblem?> check(String fileName, String source);
}
