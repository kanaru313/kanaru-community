import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/custom_font_store.dart';
import '../domain/custom_font.dart';
import 'font_providers.dart';

final customFontStoreProvider = Provider<CustomFontStore>(
  (ref) => CustomFontStore(ref.watch(fontStorageProvider)),
);

/// The fonts the user imported, sorted by name. Kept alive for the whole run.
class CustomFonts extends Notifier<List<CustomFont>> {
  @override
  List<CustomFont> build() => ref.read(customFontStoreProvider).list();

  /// Stores the font in [bytes] (read from the file [fileName]); the same
  /// bytes again give the existing font. It is not made the active font.
  /// Throws [CustomFontException].
  Future<CustomFont> importFromBytes(String fileName, Uint8List bytes) async {
    final store = ref.read(customFontStoreProvider);
    try {
      return await store.importBytes(fileName, bytes);
    } finally {
      state = store.list();
    }
  }

  /// Deletes the imported font [id]. Throws [StateError] for the font in use
  /// or an id that is not imported.
  Future<void> delete(String id) async {
    if (ref.read(activeFontIdProvider) == id) {
      throw StateError('"$id" is the font in use');
    }
    if (!state.any((f) => f.id == id)) {
      throw StateError('"$id" is not an imported font');
    }
    final store = ref.read(customFontStoreProvider);
    try {
      await store.delete(id);
    } finally {
      state = store.list();
    }
  }
}

final customFontsProvider = NotifierProvider<CustomFonts, List<CustomFont>>(
  CustomFonts.new,
);
