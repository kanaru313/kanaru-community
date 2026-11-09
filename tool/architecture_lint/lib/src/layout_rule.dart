import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'architecture_core.dart';
import 'layout_detect.dart';

/// Width-based layout APIs only in packages/kanaru_ui and lib/src/shell.
class LayoutApiRule extends AnalysisRule {
  LayoutApiRule()
      : super(
          name: 'layout_api_outside_shell',
          description: 'Width-based layout outside kanaru_ui and shell/.',
        );

  static const _code = LintCode(
    'layout_api_outside_shell',
    '{0} picks a layout by width; use it only in kanaru_ui or shell/.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => _code;

  @override
  bool get canUseParsedResult => true;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final v = _LayoutVisitor(this, context);
    registry
      ..addMethodInvocation(this, v)
      ..addPropertyAccess(this, v)
      ..addInstanceCreationExpression(this, v);
  }
}

class _LayoutVisitor extends SimpleAstVisitor<void> {
  _LayoutVisitor(this.rule, this.context);

  final LayoutApiRule rule;
  final RuleContext context;

  bool get _allowed =>
      layoutApiAllowed((context.currentUnit ?? context.definingUnit).file.path);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final api = layoutApiOfInvocation(node);
    if (api != null && !_allowed) rule.reportAtNode(node, arguments: [api]);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final api = layoutApiOfProperty(node);
    if (api != null && !_allowed) rule.reportAtNode(node, arguments: [api]);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final api = layoutApiOfCreation(node);
    if (api != null && !_allowed) rule.reportAtNode(node, arguments: [api]);
  }
}
