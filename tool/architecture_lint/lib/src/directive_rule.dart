import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as p;

import 'architecture_core.dart';
import 'config_cache.dart';

/// One rule per violation code (`module_dependency`, `domain_no_flutter`, ...)
/// over import / export / part directives, including conditional URIs.
class DirectiveRule extends AnalysisRule {
  DirectiveRule(String name, String description)
      : _code = LintCode(name, '{0}', severity: DiagnosticSeverity.ERROR),
        super(name: name, description: description);

  final LintCode _code;

  @override
  LintCode get diagnosticCode => _code;

  /// URI strings only: no resolution needed.
  @override
  bool get canUseParsedResult => true;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final v = _DirectiveVisitor(this, context);
    registry
      ..addImportDirective(this, v)
      ..addExportDirective(this, v)
      ..addPartDirective(this, v);
  }
}

class _DirectiveVisitor extends SimpleAstVisitor<void> {
  _DirectiveVisitor(this.rule, this.context);

  final DirectiveRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) =>
      _check(node.uri, node.configurations.map((c) => c.uri));

  @override
  void visitExportDirective(ExportDirective node) =>
      _check(node.uri, node.configurations.map((c) => c.uri));

  @override
  void visitPartDirective(PartDirective node) => _check(node.uri, const []);

  void _check(StringLiteral main, Iterable<StringLiteral> alternatives) {
    final unit = context.currentUnit ?? context.definingUnit;
    final loaded = ConfigCache.load(unit.file);
    if (loaded == null) return;
    final (cfgPath, cfg) = loaded;
    final root = p.dirname(cfgPath);
    final src = p.join(root, 'lib', 'src');
    final fileRel = p.isWithin(src, unit.file.path)
        ? p.posix.joinAll(p.split(p.relative(unit.file.path, from: src)))
        : null;
    for (final lit in [main, ...alternatives]) {
      final uri = lit.stringValue;
      if (uri == null) continue;
      final target = resolveToLibSrc(
        uri: uri,
        filePath: unit.file.path,
        packageRoot: root,
        packageName: cfg.package,
      );
      for (final v in checkDirective(
        config: cfg,
        fileRel: fileRel,
        uri: uri,
        targetRel: target,
      )) {
        if (v.code == rule.name) rule.reportAtNode(lit, arguments: [v.message]);
      }
    }
  }
}
