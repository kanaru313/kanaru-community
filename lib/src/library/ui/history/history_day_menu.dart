import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_days.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/history_ranges.dart';
import '../../state/history/history_providers.dart';
import '../../state/history/most_played_selection.dart';
import '../browse/library_navigation.dart';
import '../menus/menu_items.dart';
import '../menus/menu_model.dart';
import '../menus/open_menu.dart';
import 'history_delete_day.dart';
import 'history_labels.dart';
import 'history_locations.dart';
import 'history_row.dart' show HistoryDayQueue;
import 'history_toasts.dart';

/// Opens the ⋮ menu of one day (also opened by long press or right click on
/// the day's bar): play the day, shuffle it, add it to a playlist, remove it.
/// [today] names the day in the menu's head.
Future<void> openHistoryDayMenu(
  BuildContext context,
  HistoryDay day,
  DateTime today, {
  bool viaKeyboard = false,
}) => openMenu(context, (container, env) async {
  return buildHistoryDayMenu(
    env.l10n,
    day,
    today,
    clearing: container.read(historyClearingProvider),
  );
}, viaKeyboard: viaKeyboard);

/// The day menu; "Open in Most played" shows that one day there.
MenuSpec buildHistoryDayMenu(
  AppLocalizations l10n,
  HistoryDay day,
  DateTime today, {
  required bool clearing,
}) {
  final ids = HistoryDayQueue(day.plays).ids;
  final full = historyFullDate(l10n, day.start);
  final label = historyDayLabel(l10n, day.start, today);
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.tile,
      tileIcon: KIcons.dateAdded,
      seed: full,
      title: label,
      subtitle: historyDayStats(l10n, day),
    ),
    groups: [
      [
        MenuItemSpec(
          MenuItemId.play,
          icon: KIcons.play,
          title: l10n.historyMenuPlayDay,
          enabled: ids.isNotEmpty,
          action: MenuAction.run(
            (ctx) =>
                playHistoryOrToast(ctx, (a) => a.playDay(day, label: full)),
          ),
        ),
        MenuItemSpec(
          MenuItemId.shuffle,
          icon: KIcons.shuffle,
          title: l10n.libraryShuffle,
          enabled: ids.isNotEmpty,
          action: MenuAction.run(
            (ctx) => playHistoryOrToast(
              ctx,
              (a) => a.playDay(day, shuffle: true, label: full),
            ),
          ),
        ),
      ],
      [
        addToPlaylistRow(l10n, ids, full),
        MenuItemSpec(
          // The id of the "go to" rows: no dedicated id exists for this one.
          MenuItemId.link,
          icon: KIcons.mostPlayed,
          title: l10n.historyMostPlayedOpenDay,
          action: MenuAction.run((ctx) => openHistoryDayInMostPlayed(ctx, day)),
        ),
      ],
      [
        MenuItemSpec(
          MenuItemId.delete,
          icon: KIcons.delete,
          title: l10n.historyMenuDeleteDay,
          enabled: !clearing,
          danger: true,
          action: MenuAction.run((ctx) => deleteHistoryDay(ctx, day)),
        ),
      ],
    ],
  );
}

/// Sets Most played to the one day [day] and opens the page. A push, so Back
/// returns to the History page.
Future<void> openHistoryDayInMostPlayed(
  BuildContext context,
  HistoryDay day,
) async {
  final start = localDay(day.start);
  ProviderScope.containerOf(context, listen: false)
      .read(mostPlayedRangeProvider.notifier)
      .set(const MostPlayedRange().withCustom(start, start));
  unawaited(openLibraryPage<void>(context, HistoryLocations.mostPlayed));
}
