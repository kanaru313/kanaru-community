import 'dart:typed_data';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/domain/online/online_rows.dart';
import 'package:kanaru/src/lyrics/domain/online/online_text.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/lyrics/state/online/online_lookup_providers.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart';

/// A lyrics plugin as the lyrics module sees it.
LyricsSource lyricsSource(String id, {String? name, bool enabled = true}) =>
    LyricsSource(
      id: id,
      name: name ?? id,
      version: 1,
      origin: LyricsSourceOrigin.repo,
      enabled: enabled,
    );

/// Online lyrics shown for a track: [how] found it, from plugin [id].
Lyrics onlineLyrics({
  String id = 'netease',
  String name = 'NetEase',
  OnlineHow how = OnlineHow.auto,
  bool synced = true,
  int? durationMs = 252000,
}) => Lyrics(
  lines: const [LyricLine(Duration.zero, 'La la')],
  synced: synced,
  origin: LyricsOrigin.online,
  online: OnlineLyricsRef(
    providerId: id,
    providerName: name,
    remoteId: 'r1',
    how: how,
    remoteDurationMs: durationMs,
  ),
);

/// A kept copy of the track, text parsed.
OnlinePick keptPick({
  String id = 'netease',
  String name = 'NetEase',
  bool synced = true,
}) => OnlinePick(
  providerId: id,
  providerName: name,
  remoteId: 'r1',
  text: OnlineText(const [LyricLine(Duration.zero, 'La la')], synced: synced),
);

/// The plugin state the lyrics UI reads, driven by the test: the installed
/// lyrics plugins (a plugin not in [sources] counts as removed), the kept
/// copy of the track, and plugin icons by install id.
List<Override> onlineUiOverrides({
  List<LyricsSource> sources = const [],
  bool loaded = true,
  OnlinePick? pin,
  Map<String, Uint8List> icons = const {},
}) => [
  lyricsSourcesLoadedProvider.overrideWithValue(loaded),
  lyricsSourcesProvider.overrideWithValue(sources),
  lyricsPinProvider.overrideWith((ref, id) => Stream.value(pin)),
  pluginIconProvider.overrideWith((ref, id) async => icons[id]),
];
