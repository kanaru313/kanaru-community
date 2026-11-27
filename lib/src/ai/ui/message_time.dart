import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/chat_view/time_format.dart';

final _log = Logger('ai.message_footer');

/// Tells the footer time of a message that the pointer is over the message
/// (desktop): the time then shows its date too.
class MessageHoverScope extends StatefulWidget {
  const MessageHoverScope({super.key, required this.child});

  final Widget child;

  static bool hoveredOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HoverState>()?.hovered ??
      false;

  @override
  State<MessageHoverScope> createState() => _MessageHoverScopeState();
}

class _MessageHoverScopeState extends State<MessageHoverScope> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: _HoverState(hovered: _hovered, child: widget.child),
  );
}

class _HoverState extends InheritedWidget {
  const _HoverState({required this.hovered, required super.child});

  final bool hovered;

  @override
  bool updateShouldNotify(_HoverState old) => old.hovered != hovered;
}

/// "14:32" under a message. A tap (or the pointer over the message, or focus
/// on the time) opens it to "14:32 · 14/11/2026"; a tap again closes it.
class MessageTime extends StatefulWidget {
  const MessageTime({super.key, required this.at});

  final DateTime at;

  @override
  State<MessageTime> createState() => _MessageTimeState();
}

class _MessageTimeState extends State<MessageTime> {
  bool _tapped = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final open =
        _tapped ||
        _focused ||
        (desktop && MessageHoverScope.hoveredOf(context));
    final full = chatClockWithDate(widget.at);
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Semantics(
      button: true,
      expanded: open,
      label: full,
      excludeSemantics: true,
      onTap: () => setState(() => _tapped = !_tapped),
      child: InkWell(
        borderRadius: KRadius.xxs,
        onTap: () => setState(() => _tapped = !_tapped),
        onFocusChange: (f) => setState(() => _focused = f),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: desktop ? 28 : 36),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpace.x1 / 2),
              child: Text(open ? full : chatClock(widget.at), style: style),
            ),
          ),
        ),
      ),
    );
  }
}

/// Copies [text] to the clipboard. A failure is logged and left at that: a
/// clipboard that refuses is the system's business, not worth a message.
Future<void> copyMessageText(String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } on PlatformException catch (e, s) {
    _log.warning('clipboard refused the text', e, s);
  }
}

/// The [Sao chép] button of a message footer.
class MessageCopyButton extends StatelessWidget {
  const MessageCopyButton({super.key, this.text = '', this.textBuilder});

  final String text;

  /// Builds the text at the moment of the tap (it may need lookups); used
  /// instead of [text] when given.
  final Future<String> Function()? textBuilder;

  @override
  Widget build(BuildContext context) => KIconButton(
    icon: KIcons.copy,
    size: KIconSize.xs,
    padding: const EdgeInsets.all(KSpace.x2),
    tooltip: AppLocalizations.of(context).aiChatCopy,
    onPressed: () async {
      final build = textBuilder;
      await copyMessageText(build == null ? text : await build());
    },
  );
}
