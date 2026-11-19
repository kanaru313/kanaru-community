import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/domain/listen_accumulator.dart';

/// Stops of the share slider: 10 % to 100 % in steps of 5.
final listenPercentStops = <int>[for (var p = 10; p <= 100; p += 5) p];

/// "45 seconds", "1 minute 30 seconds", "4 minutes" for [ms].
String listenDuration(AppLocalizations l10n, int ms) {
  final total = ms ~/ 1000;
  if (total < 60) return l10n.settingsDurationSeconds(total);
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return seconds == 0
      ? l10n.settingsDurationMinutes(minutes)
      : l10n.settingsDurationMinutesSeconds(minutes, seconds);
}

/// The line under the row title: "4 minutes or 50 %", "Listen to the end".
String listenRuleValue(AppLocalizations l10n, ListenRule rule) {
  final end = rule.percent >= 100;
  if (rule.afterMs == 0) {
    return end
        ? l10n.settingsPlaybackListenEnd
        : l10n.settingsPlaybackListenPercentOnly(rule.percent);
  }
  final time = listenDuration(l10n, rule.afterMs);
  return end
      ? l10n.settingsPlaybackListenTimeOrEnd(time)
      : l10n.settingsPlaybackListenTimeOrPercent(time, rule.percent);
}

/// Opens the two-slider sheet of the listen rule. [current] reads the rule
/// as it is now and [save] stores a new one, so each slider keeps the other's
/// latest value however the sheet was opened.
Future<void> showListenRuleSheet(
  BuildContext context, {
  required AppLocalizations l10n,
  required ListenRule initial,
  required ListenRule Function() current,
  required void Function(ListenRule rule) save,
  GlobalKey? anchor,
}) {
  return showSliderSheet(
    context,
    anchor: anchor,
    anchorAlign: KAnchorAlign.end,
    title: Text(l10n.settingsPlaybackListenRule),
    caption: Text(l10n.settingsPlaybackListenCaption),
    sliders: [
      KStopSliderSpec<int>(
        stops: listenAfterStopsMs,
        value: initial.afterMs,
        liveLabel: (ms) => ms == 0
            ? l10n.settingsPlaybackListenNoTimeLive
            : l10n.settingsPlaybackListenTimeLive(listenDuration(l10n, ms)),
        minLabel: l10n.settingsPlaybackListenNoTime,
        maxLabel: listenDuration(l10n, listenAfterStopsMs.last),
        onCommitted: (ms) =>
            save(ListenRule(afterMs: ms, percent: current().percent)),
      ),
      KStopSliderSpec<int>(
        stops: listenPercentStops,
        value: initial.percent,
        liveLabel: (p) => p >= 100
            ? l10n.settingsPlaybackListenEndLive
            : l10n.settingsPlaybackListenPercentLive(p),
        minLabel: l10n.settingsPercent(listenPercentStops.first),
        maxLabel: l10n.settingsPlaybackListenEndLabel,
        onCommitted: (p) =>
            save(ListenRule(afterMs: current().afterMs, percent: p)),
      ),
    ],
  );
}
