import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Padding of the content of every screen of the sleep timer modal.
const sleepTimerPadding = EdgeInsets.fromLTRB(
  KSpace.x4,
  KSpace.x2,
  KSpace.x4,
  KSpace.x2,
);

/// Title row of a screen: the timer icon or a back button, the title and an
/// optional widget at the end (the "Đang chạy" chip).
class SleepTimerHeader extends StatelessWidget {
  const SleepTimerHeader({
    super.key,
    required this.title,
    this.icon = KIcons.sleepTimer,
    this.onBack,
    this.backTooltip,
    this.trailing,
  });

  final String title;
  final IconData icon;

  /// Shows a back button instead of the icon.
  final VoidCallback? onBack;
  final String? backTooltip;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final style =
        (desktop ? theme.textTheme.titleSmall : theme.textTheme.titleLarge)
            ?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      children: [
        if (onBack != null)
          KIconButton(
            icon: KIcons.back,
            tooltip: backTooltip ?? '',
            onPressed: onBack,
          )
        else
          Padding(
            padding: const EdgeInsets.all(KSpace.x2),
            child: Icon(
              icon,
              size: KIconSize.md,
              color: theme.colorScheme.primary,
            ),
          ),
        const SizedBox(width: KSpace.x2),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: style, maxLines: 2),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: KSpace.x2),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}

/// Buttons at the bottom of a screen: side by side filling the width on touch
/// shells, at the end on desktop.
class SleepTimerFooter extends StatelessWidget {
  const SleepTimerFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final spaced = <Widget>[
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: KSpace.x2),
        desktop ? Flexible(child: children[i]) : Expanded(child: children[i]),
      ],
    ];
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x2),
      child: Row(
        mainAxisAlignment: desktop
            ? MainAxisAlignment.end
            : MainAxisAlignment.center,
        children: spaced,
      ),
    );
  }
}

/// A line of small text under a title (the hint of the first screen).
class SleepTimerCaption extends StatelessWidget {
  const SleepTimerCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    return Text(
      text,
      style: (desktop ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

/// A group title ("Sau một khoảng", "Theo bài").
class SleepTimerSection extends StatelessWidget {
  const SleepTimerSection(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x4, bottom: KSpace.x2),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
