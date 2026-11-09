import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/directive_rule.dart';
import 'src/layout_rule.dart';

/// Entry point the analysis server loads (`plugins:` in analysis_options.yaml).
final plugin = KanaruArchitecturePlugin();

class KanaruArchitecturePlugin extends Plugin {
  @override
  String get name => 'kanaru_architecture';

  @override
  void register(PluginRegistry registry) {
    // Warning rules are enabled by default; their code severity is ERROR.
    for (final rule in [
      DirectiveRule('module_dependency', 'Import crosses the module DAG.'),
      DirectiveRule('domain_no_flutter', 'domain/ imports Flutter.'),
      DirectiveRule('domain_layer', 'domain/ imports data/, state/ or ui/.'),
      DirectiveRule('package_imports_app', 'kanaru_ui imports the app.'),
      DirectiveRule('screens_no_data', 'screens/ imports data/ or database/.'),
      DirectiveRule('rust_only_from_data', 'rust/ imported outside data/.'),
      LayoutApiRule(),
    ]) {
      registry.registerWarningRule(rule);
    }
  }
}
