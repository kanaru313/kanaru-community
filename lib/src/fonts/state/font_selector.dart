import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../domain/app_font.dart';
import '../domain/builtin_fonts.dart';
import 'font_providers.dart';

final _log = Logger('font_selector');

/// How a [FontSelector.select] request ended.
enum FontSelectResult {
  /// The font is now the active one.
  applied,

  /// The font could not be loaded or saved; the previous font stays.
  failed,

  /// A newer request came in while this one was loading; it decides.
  superseded,
}

/// Switches the app font. Loading a downloaded or imported font takes time, so
/// only the latest request may change the setting: tapping a slow font and
/// then another one ends on the second.
class FontSelector {
  FontSelector(this._ref);

  final Ref _ref;
  int _latest = 0;

  Future<FontSelectResult> select(AppFont font) async {
    final request = ++_latest;
    try {
      await _ref
          .read(fontLoaderProvider)
          .ensureLoaded(font, _ref.read(fontStorageProvider));
    } on Object catch (e, st) {
      _log.warning('cannot load font "${font.id}"', e, st);
      return request == _latest
          ? FontSelectResult.failed
          : FontSelectResult.superseded;
    }
    if (request != _latest) return FontSelectResult.superseded;
    final setting = _ref.read(activeFontIdProvider.notifier);
    final previous = _ref.read(activeFontIdProvider);
    try {
      await setting.set(font.id);
    } on Object catch (e, st) {
      // The notifier shows the new id before the write: put the old one back
      // so the screen matches what is stored.
      _log.warning('cannot save font "${font.id}"', e, st);
      try {
        await setting.set(previous);
      } on Object catch (_) {
        // Memory is already back on the old id; the store is unwritable.
      }
      return FontSelectResult.failed;
    }
    return FontSelectResult.applied;
  }
}

final fontSelectorProvider = Provider<FontSelector>(FontSelector.new);

/// The font in use (`app.font`; an unknown id gives the default font).
final activeFontProvider = Provider<AppFont>(
  (ref) => appFontFor(ref.watch(activeFontIdProvider)),
);
