import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';
import 'k_info_row_value.dart';
import 'k_overlay_page_scope.dart';

/// One label + value line of a [KInfoGroup], at least 48 dp tall.
///
/// Label column 112 on a page, 148 in a box ([KOverlayPageScope]); at 200 %
/// text the label sits above the value. Shows, first match: [soon] (dimmed,
/// never copied), [value], [valueWidget] (links: no copy, no selection),
/// [unknownText] (italic). [missing]: `error`, struck through.
///
/// Copy (decided here, not by the call site): desktop shell = selectable text,
/// hover tints 4 % and shows a 32 dp copy button; mobile / tablet = long
/// press copies and flashes the row; a mouse hovering shows the button on any
/// shell. It copies [copyText] or [value], then calls [onCopied] (the
/// SnackBar is the caller's). Semantics: "label: value".
class KInfoRow extends StatefulWidget {
  const KInfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.unknownText,
    this.soon,
    this.copyText,
    this.onCopied,
    this.trailing,
    this.missing = false,
  }) : assert(
         value != null ||
             valueWidget != null ||
             unknownText != null ||
             soon != null,
         'a row needs a value, a widget, unknownText or soon',
       );

  final String label;
  final String? value;
  final Widget? valueWidget;

  /// Shown italic when there is no value ("Không rõ"; the caller localises).
  final String? unknownText;

  /// A not-yet-available field: this text ("Sắp có") dims the row.
  final String? soon;

  /// What is copied when it differs from [value] (the raw path, say).
  final String? copyText;
  final ValueChanged<String>? onCopied;

  /// Buttons at the end of the row (path actions).
  final Widget? trailing;
  final bool missing;

  @override
  State<KInfoRow> createState() => _KInfoRowState();
}

class _KInfoRowState extends State<KInfoRow> {
  bool _hover = false;
  bool _flash = false;
  Timer? _flashTimer;

  String? get _copyable {
    if (widget.soon != null || widget.valueWidget != null) return null;
    final text = widget.copyText ?? widget.value;
    return (text == null || text.isEmpty) ? null : text;
  }

  Future<void> _copy() async {
    final text = _copyable;
    if (text == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } on PlatformException {
      return; // The clipboard refused: no flash, no "copied" message.
    }
    if (!mounted) return;
    setState(() => _flash = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(KMotion.flash, () {
      if (mounted) setState(() => _flash = false);
    });
    widget.onCopied?.call(text);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final stacked = MediaQuery.textScalerOf(context).scale(10) >= 17.5;
    final box = KOverlayPageScope.maybeKindOf(context) == KOverlayKind.box;
    final copyable = _copyable != null;
    final link = widget.valueWidget != null && widget.soon == null;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final copyHint = MaterialLocalizations.of(context).copyButtonLabel;

    final shown = widget.soon ?? widget.value;
    // What a screen reader says after the label; null for a row of links.
    final spoken = link ? null : (shown ?? widget.unknownText);
    final value = buildInfoRowValue(
      context,
      valueWidget: link ? widget.valueWidget : null,
      shown: shown,
      unknownText: widget.unknownText,
      missing: widget.missing,
      selectable: desktop && copyable,
    );
    final content = buildInfoRowContent(
      context,
      label: widget.label,
      value: value,
      stacked: stacked,
      labelWidth: box ? 148 : 112,
    );
    final showButton = copyable && _hover;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: copyable && !desktop ? _copy : null,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : KMotion.fast,
          color: _flash
              ? scheme.onSurface.withValues(alpha: 0.08)
              : _hover && copyable
              ? scheme.onSurface.withValues(alpha: 0.04)
              : const Color(0x00000000),
          constraints: const BoxConstraints(minHeight: KLayout.minTarget),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x2,
          ),
          child: Opacity(
            opacity: widget.soon != null ? 0.5 : 1,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    container: true,
                    label: spoken == null ? null : '${widget.label}: $spoken',
                    hint: copyable ? copyHint : null,
                    onLongPress: copyable ? _copy : null,
                    child: ExcludeSemantics(
                      excluding: spoken != null,
                      child: content,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
                if ((desktop && copyable) || showButton)
                  SizedBox(
                    width: 32,
                    child: showButton
                        ? KIconButton(
                            tooltip: copyHint,
                            icon: KIcons.copy,
                            size: KIconSize.sm,
                            padding: const EdgeInsets.all(6),
                            onPressed: _copy,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
