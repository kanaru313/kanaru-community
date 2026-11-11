import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Tells a button's `onPressed` whether the button was activated with the
/// keyboard (Enter, Space): [builder] gets a function that answers it, to call
/// inside `onPressed`. A pointer press resets the answer to false.
class ViaKeyboardTracker extends StatefulWidget {
  const ViaKeyboardTracker({super.key, required this.builder});

  final Widget Function(BuildContext context, bool Function() viaKeyboard)
  builder;

  @override
  State<ViaKeyboardTracker> createState() => _ViaKeyboardTrackerState();
}

class _ViaKeyboardTrackerState extends State<ViaKeyboardTracker> {
  /// Set by an activation key going down on the button, cleared by its key up
  /// or any pointer press.
  bool _byKey = false;

  static final _activation = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.select,
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_activation.contains(event.logicalKey)) {
      _byKey = event is! KeyUpEvent;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _byKey = false,
    child: Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: widget.builder(context, () => _byKey),
    ),
  );
}

/// The ⋮ button of a tile, card or page: opens the item's menu. [onPressed]
/// is told whether the button was activated with the keyboard, so the menu can
/// focus its first row.
class LibraryMoreButton extends StatelessWidget {
  const LibraryMoreButton({super.key, required this.onPressed});

  final void Function({required bool viaKeyboard}) onPressed;

  @override
  Widget build(BuildContext context) => ViaKeyboardTracker(
    builder: (context, viaKeyboard) => IconButton(
      tooltip: AppLocalizations.of(context).libraryMenuMore,
      onPressed: () => onPressed(viaKeyboard: viaKeyboard()),
      icon: const Icon(KIcons.moreVert),
    ),
  );
}
