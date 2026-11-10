import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/browse/selection_providers.dart';
import 'selection_shortcuts.dart';

/// Whether a dialog, sheet or page sits on the root navigator above the app
/// (the app's own pages are branch routes, so they do not count).
bool rootModalOpen(BuildContext context) =>
    Navigator.maybeOf(context, rootNavigator: true)?.canPop() ?? false;

/// Back and Esc for the open selection panel: they collapse it, once nothing
/// is on top of it. They never clear the selection (only the panel's ✕ does).
///
/// - Back: a `BackButtonListener`. The root back dispatcher asks listeners
///   before the router pops a sheet or dialog, so the listener answers only
///   when the panel is expanded and the route it sits in is the current one
///   (no modal above it); otherwise the modal closes first.
/// - Esc: a key handler with the same two conditions that also yields while a
///   text field has focus (Esc then closes that field).
class SelectionBackScope extends ConsumerStatefulWidget {
  const SelectionBackScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SelectionBackScope> createState() => _SelectionBackScopeState();
}

class _SelectionBackScopeState extends ConsumerState<SelectionBackScope> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// Collapses the panel when it is open and nothing covers it.
  bool _collapse() {
    if (!mounted) return false;
    if (!ref.read(librarySelectionProvider).expanded) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    ref.read(librarySelectionProvider.notifier).setExpanded(false);
    return true;
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (textFieldHasFocus()) return false;
    return _collapse();
  }

  @override
  Widget build(BuildContext context) => BackButtonListener(
    onBackButtonPressed: () async => _collapse(),
    child: widget.child,
  );
}
