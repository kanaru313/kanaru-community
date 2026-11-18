import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_icon_size.dart';
import 'k_icon_button.dart';

/// Centred dialog using the theme's soft shape, capped at [maxWidth]
/// ([KLayout.dialog]; [KLayout.dialogWide] for the wide ones).
Future<T?> showKDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = KLayout.dialog,
}) {
  return showDialog<T>(
    context: context,
    // Center loosens the route's tight screen constraints, so the cap holds.
    builder: (context) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: builder(context),
      ),
    ),
  );
}

/// Asks for confirmation. True only when the user confirms; Cancel, Back and
/// a tap on the scrim all give false.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showKDialog<bool>(
    context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Full-screen dialog on the root navigator, for forms on the mobile shell.
/// App bar: [closeTooltip] close button, [title], then the [actionLabel]
/// text button. The [body] scrolls and resizes with the keyboard, so the
/// action stays visible.
///
/// The action is enabled by [actionEnabledListenable] when given (it is
/// listened to, so a form can enable it as it becomes valid), else by
/// [actionEnabled]. Pressing it runs [onAction]; meanwhile the action shows a
/// progress indicator in place of its label (the label stays in semantics),
/// the action is disabled and the close button and Back are blocked. If
/// [onAction] throws, the dialog stays open, the busy state clears and the
/// error goes to [FlutterError.reportError]: the caller shows its own message.
///
/// The dialog never pops itself on success: the caller pops it from inside
/// [onAction] (`Navigator.pop(context, result)`), and that result is what
/// this future completes with. The close button and Back complete it with
/// null.
Future<T?> showKFullScreenDialog<T>(
  BuildContext context, {
  required String title,
  required String closeTooltip,
  required String actionLabel,
  required Future<void> Function() onAction,
  bool actionEnabled = true,
  ValueListenable<bool>? actionEnabledListenable,
  required WidgetBuilder body,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute<T>(
      fullscreenDialog: true,
      builder: (context) => _FullScreenDialog(
        title: title,
        closeTooltip: closeTooltip,
        actionLabel: actionLabel,
        onAction: onAction,
        actionEnabled: actionEnabled,
        actionEnabledListenable: actionEnabledListenable,
        body: body,
      ),
    ),
  );
}

class _FullScreenDialog extends StatefulWidget {
  const _FullScreenDialog({
    required this.title,
    required this.closeTooltip,
    required this.actionLabel,
    required this.onAction,
    required this.actionEnabled,
    required this.actionEnabledListenable,
    required this.body,
  });

  final String title;
  final String closeTooltip;
  final String actionLabel;
  final Future<void> Function() onAction;
  final bool actionEnabled;
  final ValueListenable<bool>? actionEnabledListenable;
  final WidgetBuilder body;

  @override
  State<_FullScreenDialog> createState() => _FullScreenDialogState();
}

class _FullScreenDialogState extends State<_FullScreenDialog> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onAction();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'kanaru_ui',
          context: ErrorDescription(
            'while running a full-screen dialog action',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _action(bool enabled) {
    final active = enabled && !_busy;
    return TextButton(
      onPressed: active ? _run : null,
      child: _busy
          ? Semantics(
              label: widget.actionLabel,
              child: const SizedBox.square(
                dimension: KIconSize.sm,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Text(widget.actionLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenable = widget.actionEnabledListenable;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: KIconButton(
            icon: KIcons.close,
            tooltip: widget.closeTooltip,
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          title: Text(widget.title),
          actions: [
            listenable == null
                ? _action(widget.actionEnabled)
                : ValueListenableBuilder<bool>(
                    valueListenable: listenable,
                    builder: (context, enabled, _) => _action(enabled),
                  ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(child: widget.body(context)),
        ),
      ),
    );
  }
}
