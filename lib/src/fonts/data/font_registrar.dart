import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../domain/app_font.dart';
import 'font_storage.dart';

final _log = Logger('font_registrar');

/// Registers all [fonts] (the weights) of [family] with the engine.
typedef FontBytesRegistrar = Future<void> Function(
  String family,
  List<Uint8List> fonts,
);

Future<void> _registerWithEngine(String family, List<Uint8List> fonts) async {
  final loader = FontLoader(family);
  for (final bytes in fonts) {
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Loads downloaded and imported fonts into the engine, once per family.
class FontRegistrar {
  FontRegistrar({FontBytesRegistrar? registrar})
    : _registrar = registrar ?? _registerWithEngine;

  final FontBytesRegistrar _registrar;
  final Set<String> _loaded = {};
  final Map<String, Future<void>> _inFlight = {};
  final Set<String> _licensed = {};

  bool isFamilyLoaded(String family) => _loaded.contains(family);

  /// Makes sure [font] is registered. No-op for built-in fonts. Concurrent
  /// calls for one family share one load; a failed load can be retried.
  /// Throws [StateError] when the font has no files on disk.
  Future<void> ensureLoaded(AppFont font, FontStorage storage) {
    if (font.isBuiltIn || _loaded.contains(font.family)) return Future.value();
    final pending = _inFlight[font.family];
    if (pending != null) return pending;
    // Cleared only after the entry is stored: a load that fails before its
    // first await would otherwise leave its failure cached for good.
    final load = _load(font, storage).whenComplete(() {
      // A block, not an arrow: whenComplete waits on a returned future, and
      // Map.remove would return this very load.
      _inFlight.remove(font.family);
    });
    _inFlight[font.family] = load;
    return load;
  }

  Future<void> _load(AppFont font, FontStorage storage) async {
    final files = storage.fontFiles(font);
    if (files.isEmpty) {
      throw StateError('Font "${font.id}" is not installed on disk');
    }
    final bytes = <Uint8List>[for (final f in files) await f.readAsBytes()];
    await _registrar(font.family, bytes);
    _loaded.add(font.family);
    _log.info('Loaded family "${font.family}" (${files.length} files)');
  }

  /// Adds [licenseText] to the licenses page, once per [label].
  void registerLicense(String label, String licenseText) {
    if (!_licensed.add(label)) return;
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([label], licenseText);
    });
  }
}
