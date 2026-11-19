import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Where the setup blocks (folders, exclusions, tabs, permissions) are shown.
/// The first-run page is the default; Settings › Library reuses the same
/// widgets in [settings] mode.
enum SetupMode {
  /// The welcome screen: the explanation stays visible under the title and
  /// an edit only changes the list.
  firstRun,

  /// Settings › Library: the explanation sits behind the section's ⓘ, and a
  /// change of folders or exclusions rescans in the background.
  settings,
}

/// A [SetupSection] captioned for [mode].
///
/// [caption] explains the whole section: visible under the title in
/// [SetupMode.firstRun], behind the ⓘ in [SetupMode.settings]. [state] is what
/// the section shows right now (a missing permission, an estimate): it stays
/// visible in both modes and, in first run, replaces [caption].
SetupSection captionedSection(
  BuildContext context, {
  required SetupMode mode,
  required String title,
  required String caption,
  String? state,
  required List<Widget> children,
  bool card = true,
}) {
  switch (mode) {
    case SetupMode.firstRun:
      return SetupSection(
        title: Text(title),
        subtitle: Text(state ?? caption),
        card: card,
        children: children,
      );
    case SetupMode.settings:
      return SetupSection(
        title: Text(title),
        subtitle: state == null ? null : Text(state),
        hint: caption,
        hintTooltip: AppLocalizations.of(context)
            .settingsSectionHintTooltip(title),
        hintTitle: title,
        card: card,
        children: children,
      );
  }
}
