import 'package:analyzer/dart/ast/ast.dart';

/// Name of the width-based layout API used by [node], or null. Works on
/// unresolved ASTs: an unresolved `LayoutBuilder(...)` parses as a method call.
String? layoutApiOfInvocation(MethodInvocation node) {
  final target = node.target;
  if (target is SimpleIdentifier &&
      target.name == 'MediaQuery' &&
      const {'sizeOf', 'maybeSizeOf'}.contains(node.methodName.name)) {
    return 'MediaQuery.${node.methodName.name}';
  }
  if (target == null && node.methodName.name == 'LayoutBuilder') {
    return 'LayoutBuilder';
  }
  return null;
}

/// Same as [layoutApiOfInvocation] for `LayoutBuilder(...)` / `const LayoutBuilder(...)`.
String? layoutApiOfCreation(InstanceCreationExpression node) =>
    node.constructorName.type.name.lexeme == 'LayoutBuilder' ? 'LayoutBuilder' : null;
