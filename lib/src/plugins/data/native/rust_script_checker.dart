import '../../../rust/api/plugin_runtime.dart' as rust;
import '../../domain/install/script_checker.dart';

/// The syntax check of a plugin script by the Rust runtime (it compiles the
/// code and runs nothing). FRB is initialised at startup; this never calls
/// `RustLib.init`, so when the native library is not loaded the call throws
/// and the package is refused rather than accepted unchecked.
class RustScriptChecker implements ScriptChecker {
  const RustScriptChecker();

  @override
  Future<ScriptProblem?> check(String fileName, String source) async {
    final problem = await rust.checkPluginScript(name: fileName, code: source);
    if (problem == null) return null;
    return ScriptProblem(
      line: problem.line > 0 ? problem.line : null,
      message: problem.message,
    );
  }
}
