import 'package:analyzer/dart/ast/ast.dart';

const _mediaQueryWidthCalls = {
  'sizeOf',
  'maybeSizeOf',
  'widthOf',
  'heightOf',
  'maybeWidthOf',
  'maybeHeightOf',
};

/// True when [target] names `MediaQuery`, bare or import-prefixed
/// (`MediaQuery`, `w.MediaQuery`).
bool _isMediaQuery(Expression? target) => switch (target) {
      SimpleIdentifier(:final name) => name == 'MediaQuery',
      PrefixedIdentifier(:final identifier) => identifier.name == 'MediaQuery',
      PropertyAccess(:final propertyName) => propertyName.name == 'MediaQuery',
      _ => false,
    };

/// Name of the width-based layout API used by [node], or null. Works on
/// unresolved ASTs: an unresolved `LayoutBuilder(...)` parses as a method call
/// (`w.LayoutBuilder(...)` has a prefix as target).
String? layoutApiOfInvocation(MethodInvocation node) {
  final name = node.methodName.name;
  if (_isMediaQuery(node.target) && _mediaQueryWidthCalls.contains(name)) {
    return 'MediaQuery.$name';
  }
  final target = node.target;
  if (name == 'LayoutBuilder' && (target == null || target is SimpleIdentifier)) {
    return 'LayoutBuilder';
  }
  return null;
}

/// `MediaQuery.of(context).size` and `MediaQuery.maybeOf(context)?.size`.
String? layoutApiOfProperty(PropertyAccess node) {
  final inner = node.target;
  if (node.propertyName.name == 'size' &&
      inner is MethodInvocation &&
      _isMediaQuery(inner.target) &&
      (inner.methodName.name == 'of' || inner.methodName.name == 'maybeOf')) {
    return 'MediaQuery.${inner.methodName.name}(...).size';
  }
  return null;
}

/// Same as [layoutApiOfInvocation] for `LayoutBuilder(...)` / `const LayoutBuilder(...)`
/// (also `w.LayoutBuilder(...)`: the prefix is not part of the type name).
String? layoutApiOfCreation(InstanceCreationExpression node) =>
    node.constructorName.type.name.lexeme == 'LayoutBuilder' ? 'LayoutBuilder' : null;
