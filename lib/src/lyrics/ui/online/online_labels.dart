import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/online/lookup_outcome.dart';
import '../../domain/online/online_lyrics_ref.dart';
import 'online_row_info.dart';

/// "21:05": a time of day in the user's clock style (12 or 24 hours).
String formatClock(BuildContext context, DateTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// "Đồng bộ" / "Thường".
String onlineKindLabel(AppLocalizations l10n, {required bool synced}) =>
    synced ? l10n.lyricsKindSynced : l10n.lyricsKindPlain;

/// "NetEase · Đồng bộ": the short name of online lyrics (tooltip, song menu).
/// An instrumental result has no kind to name.
String onlineSourceLabel(
  AppLocalizations l10n, {
  required String plugin,
  required bool synced,
  bool instrumental = false,
}) => instrumental
    ? l10n.lyricsInstrumentalTitle
    : l10n.lyricsOnlineLabel(plugin, onlineKindLabel(l10n, synced: synced));

/// The detail line of the "Bản trực tuyến" row: "NetEase · Đồng bộ · 4:12 ·
/// tự tìm" (a kept copy has no suffix), or "ZingMP3 · plugin đã gỡ · Đồng bộ · 4:12" when
/// the plugin is gone.
String onlineRowSubtitle(
  AppLocalizations l10n,
  OnlineRowInfo info, {
  required bool removed,
}) {
  final parts = <String>[
    info.providerName,
    if (removed) l10n.lyricsOnlineRemoved,
    info.instrumental
        ? l10n.lyricsOnlineInstrumental
        : onlineKindLabel(l10n, synced: info.synced),
    if (info.duration != null) _minutes(info.duration!),
    if (info.how == OnlineHow.auto) l10n.lyricsOnlineAuto,
  ];
  return parts.join(' · ');
}

String _minutes(Duration d) {
  final seconds = d.inSeconds;
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// The failure reason of the lyrics area: "Lỗi mạng khi tìm ở 2 nguồn đang
/// bật", "Các nguồn cần cấu hình", "Nguồn lời không trả lời".
String failReasonLong(
  AppLocalizations l10n,
  LookupFailReason reason,
  int asked,
) => switch (reason) {
  LookupFailReason.network => l10n.lyricsFailNetwork(asked),
  LookupFailReason.needsConfig => l10n.lyricsFailNeedsConfig,
  LookupFailReason.noAnswer => l10n.lyricsFailNoAnswer,
};

/// The short reason of the "Lời cho bài này" status line: "lỗi mạng".
String failReasonShort(AppLocalizations l10n, LookupFailReason reason) =>
    switch (reason) {
      LookupFailReason.network => l10n.lyricsFailShortNetwork,
      LookupFailReason.needsConfig => l10n.lyricsFailShortNeedsConfig,
      LookupFailReason.noAnswer => l10n.lyricsFailShortNoAnswer,
    };

/// The sentence of the "Tìm lỗi" state: the reason, with the retry time when
/// one is scheduled.
String failedAreaMessage(
  BuildContext context,
  LookupFailReason reason,
  int asked,
  DateTime? retryAt,
) {
  final l10n = AppLocalizations.of(context);
  final why = failReasonLong(l10n, reason, asked);
  return retryAt == null
      ? l10n.lyricsFailedMessage(why)
      : l10n.lyricsFailedMessageRetry(why, formatClock(context, retryAt));
}
