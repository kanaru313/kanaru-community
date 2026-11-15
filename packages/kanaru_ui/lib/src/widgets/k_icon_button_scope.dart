import 'package:flutter/widgets.dart';

/// Marks the subtree of a `KIconButton` so [primaryFocusInsideKIconButton] can
/// tell its focus node from any other.
class KIconButtonScope extends InheritedWidget {
  const KIconButtonScope({super.key, required super.child});

  @override
  bool updateShouldNotify(KIconButtonScope oldWidget) => false;
}

/// True when the primary focus sits inside a `KIconButton`.
bool primaryFocusInsideKIconButton() {
  final context = FocusManager.instance.primaryFocus?.context;
  return context != null &&
      context.getInheritedWidgetOfExactType<KIconButtonScope>() != null;
}
