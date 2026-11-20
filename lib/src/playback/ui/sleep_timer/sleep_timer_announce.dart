import 'dart:async';
import 'dart:ui' show FlutterView;

import 'package:flutter/semantics.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/sleep_timer_state.dart';
import 'sleep_timer_texts.dart';

final _log = Logger('SleepTimerAnnounce');

/// What a screen reader is told when the timer changes. Said only on events
/// (start, hold, resume, cancel, expiry); nothing per second.
extension SleepTimerAnnouncements on SleepTimerTexts {
  /// After a start: "Đã hẹn giờ ngủ 15 phút, dừng lúc 23:40". [started] is
  /// the state right after the start.
  String announceStart(SleepTimerState started, DateTime now) {
    switch (started.mode) {
      case SleepTimerMode.minutes:
        final minutes = started.setLength.inMinutes;
        return l10n.sleepTimerAnnounceStartMinutes(
          durationWords(minutes),
          clockAt(started.endsAt ?? now.add(started.setLength)),
        );
      case SleepTimerMode.tracks:
        return l10n.sleepTimerAnnounceStartTracks(started.tracksAtStart);
      case SleepTimerMode.endOfTrack:
        return l10n.sleepTimerAnnounceStartEndTrack;
      case SleepTimerMode.endOfAlbum:
        return l10n.sleepTimerAnnounceStartEndAlbum;
      case SleepTimerMode.endOfQueue || null:
        return l10n.sleepTimerAnnounceStartEndQueue;
    }
  }

  String get announceHeld => l10n.sleepTimerAnnounceHeld;
  String get announceResumed => l10n.sleepTimerAnnounceResumed;
  String get announceCancelled => l10n.sleepTimerAnnounceCancelled;
  String get announceExpired => l10n.sleepTimerAnnounceExpired;
}

/// Speaks a sleep timer message. It captures the view and text direction when
/// made, so it still works after the modal that made it has closed (a tile
/// starts the timer and closes at once).
class SleepTimerAnnouncer {
  const SleepTimerAnnouncer(this.view, this.direction);

  factory SleepTimerAnnouncer.of(BuildContext context) =>
      SleepTimerAnnouncer(View.of(context), Directionality.of(context));

  final FlutterView view;
  final TextDirection direction;

  /// A failing platform channel is logged, never thrown: an announcement is
  /// a courtesy.
  void say(String message) {
    unawaited(
      SemanticsService.sendAnnouncement(view, message, direction).catchError((
        Object e,
      ) {
        _log.fine('announce failed: ${e.runtimeType}');
      }),
    );
  }
}
