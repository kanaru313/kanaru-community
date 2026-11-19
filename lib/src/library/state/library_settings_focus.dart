import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A block of Settings › Library that another screen can ask to be shown.
enum LibrarySettingsAnchor {
  /// "Music folders", reached from the empty library.
  folders,
}

/// One request: [seq] is new on every call, so asking for the same anchor
/// twice is two different requests.
typedef LibrarySettingsFocusRequest = ({LibrarySettingsAnchor anchor, int seq});

/// The one-shot signal "show this block of Settings › Library". It is not
/// part of the URL: the location stays `/settings/library`, so Back never
/// replays it. The page reads it (also when it is already mounted behind
/// another tab), scrolls and pulses, then clears it.
class LibrarySettingsFocus extends Notifier<LibrarySettingsFocusRequest?> {
  int _seq = 0;

  @override
  LibrarySettingsFocusRequest? build() => null;

  void request(LibrarySettingsAnchor anchor) =>
      state = (anchor: anchor, seq: ++_seq);

  void clear() => state = null;

  /// Clears only while [request] is still the current one (a newer request
  /// stays).
  void clearIf(LibrarySettingsFocusRequest request) {
    if (state == request) state = null;
  }
}

final librarySettingsFocusProvider =
    NotifierProvider<LibrarySettingsFocus, LibrarySettingsFocusRequest?>(
      LibrarySettingsFocus.new,
    );
