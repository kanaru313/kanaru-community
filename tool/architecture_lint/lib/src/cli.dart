import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'architecture_core.dart';
import 'layout_detect.dart';

/// CLI twin of the analyzer plugin. Ignores `// ignore:` comments and fails on
/// the ones that target architecture rules. Exit codes: 0 clean, 1 violations,
/// 2 bad architecture.yaml.
int run(List<String> args, {StringSink? out, StringSink? err}) {
  final output = out ?? stdout;
  final errors = err ?? stderr;
  final root = p.normalize(p.absolute(args.isEmpty ? '.' : args.first));
  final configFile = File(p.join(root, 'architecture.yaml'));
  if (!configFile.existsSync()) {
    errors.writeln('architecture.yaml not found in $root');
    return 2;
  }
  final ArchitectureConfig cfg;
  try {
    cfg = ArchitectureConfig.parse(configFile.readAsStringSync());
  } on Object catch (e) {
    errors.writeln('architecture.yaml is invalid: $e');
    return 2;
  }
  final cycle = cfg.findCycle();
  if (cycle != null) {
    errors.writeln('architecture.yaml has a cycle: $cycle');
    return 2;
  }

  final reports = <String>[];
  for (final file in _dartFiles(root)) {
    reports.addAll(_checkFile(file, root, cfg));
  }
  for (final r in reports) {
    output.writeln(r);
  }
  output.writeln(reports.isEmpty ? 'architecture OK' : '${reports.length} violation(s)');
  return reports.isEmpty ? 0 : 1;
}

/// App sources plus workspace package sources, minus generated code.
Iterable<File> _dartFiles(String root) sync* {
  final dirs = [
    Directory(p.join(root, 'lib')),
    ...?_packageLibs(root),
  ];
  for (final dir in dirs.where((d) => d.existsSync())) {
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      final rel = p.posix.joinAll(p.split(p.relative(f.path, from: root)));
      if (!f.path.endsWith('.dart')) continue;
      if (rel.startsWith('lib/src/rust/') || rel.startsWith('lib/l10n/gen/')) continue;
      if (rel.endsWith('.g.dart') || rel.endsWith('.drift.dart')) continue;
      yield f;
    }
  }
}

List<Directory>? _packageLibs(String root) {
  final packages = Directory(p.join(root, 'packages'));
  if (!packages.existsSync()) return null;
  return [
    for (final d in packages.listSync().whereType<Directory>()) Directory(p.join(d.path, 'lib')),
  ];
}

List<String> _checkFile(File file, String root, ArchitectureConfig cfg) {
  final content = file.readAsStringSync();
  final unit = parseString(content: content, path: file.path, throwIfDiagnostics: false).unit;
  final shown = p.relative(file.path, from: root);
  final out = <String>[];
  void report(int offset, String message, String code) {
    final loc = unit.lineInfo.getLocation(offset);
    out.add('$shown:${loc.lineNumber}:${loc.columnNumber}: error: $message [$code]');
  }

  // Forbidden ignore comments.
  var offset = 0;
  for (final line in content.split('\n')) {
    if (isArchitectureIgnore(line)) {
      report(offset + line.indexOf('//'), 'ignore comments may not silence architecture rules.', 'architecture_ignore');
    }
    offset += line.length + 1;
  }

  // Import / export / part rules apply to files inside the app's lib/src; a
  // kanaru_ui may not import the app.
  final src = p.join(root, 'lib', 'src');
  final fileRel = p.isWithin(src, file.path)
      ? p.posix.joinAll(p.split(p.relative(file.path, from: src)))
      : null;
  final inPackage = p.isWithin(p.join(root, 'packages', 'kanaru_ui'), file.path);
  if (fileRel != null) {
    final loose = fileOutsideModule(fileRel);
    if (loose != null) {
      report(0, loose.message, loose.code);
    }
  }
  if (fileRel != null || inPackage) {
    for (final d in unit.directives.whereType<UriBasedDirective>()) {
      final lits = [d.uri, if (d is NamespaceDirective) ...d.configurations.map((c) => c.uri)];
      for (final lit in lits) {
        final uri = lit.stringValue;
        if (uri == null) continue;
        final violations = [
          ...checkDirective(
            config: cfg,
            fileRel: fileRel,
            uri: uri,
            targetRel: resolveToLibSrc(
              uri: uri,
              filePath: file.path,
              packageRoot: root,
              packageName: cfg.package,
            ),
            targetRootFile: resolveToCompositionRoot(
              uri: uri,
              filePath: file.path,
              packageRoot: root,
              packageName: cfg.package,
            ),
          ),
          if (inPackage) ...[packageImportsApp(cfg, uri)].nonNulls,
        ];
        for (final v in violations) {
          // Reported once per file above.
          if (v.message == outsideModuleMessage) continue;
          report(lit.offset, v.message, v.code);
        }
      }
    }
  }

  // Layout rule.
  if (!layoutApiAllowed(file.path)) {
    unit.accept(_LayoutScan((node, api) => report(
          node.offset,
          '$api picks a layout by width; use it only in kanaru_ui or shell/.',
          'layout_api_outside_shell',
        )));
  }
  return out;
}

class _LayoutScan extends RecursiveAstVisitor<void> {
  _LayoutScan(this.onHit);

  final void Function(AstNode node, String api) onHit;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final api = layoutApiOfInvocation(node);
    if (api != null) onHit(node, api);
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final api = layoutApiOfProperty(node);
    if (api != null) onHit(node, api);
    super.visitPropertyAccess(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final api = layoutApiOfCreation(node);
    if (api != null) onHit(node, api);
    super.visitInstanceCreationExpression(node);
  }
}
