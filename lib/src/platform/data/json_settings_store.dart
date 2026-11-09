import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../domain/settings_store.dart';
import 'atomic_file.dart';

const _format = 'kanaru-settings';
const _version = 1;
const _maxRetries = 5;
const _retryDelay = Duration(seconds: 5);

/// [SettingsStore] backed by one JSON file, `{"format", "version", "values"}`.
/// Reads are served from memory; writes are coalesced and atomic.
class JsonSettingsStore implements SettingsStore {
  JsonSettingsStore._(this._file, this._values, this._delay, this._timerFactory);

  static final _log = Logger('settings');

  final File _file;
  final Map<String, Object?> _values;
  final Duration _delay;
  final Timer Function(Duration, void Function()) _timerFactory;
  // Not sync: a listener may write again without hitting a nested add.
  final _changes = StreamController<String>.broadcast();
  int _failures = 0;
  Timer? _timer;
  bool _dirty = false;
  Future<void> _writing = Future.value();

  /// Loads [file]. A file that cannot be used as ours is copied to
  /// `<file>.bad-<epoch ms>` and the store starts empty; this never throws.
  static Future<JsonSettingsStore> open(
    File file, {
    Duration writeDelay = const Duration(milliseconds: 250),
    Timer Function(Duration, void Function()) timerFactory = Timer.new,
  }) async {
    final values = <String, Object?>{};
    try {
      final stale = File('${file.path}.tmp');
      if (await stale.exists()) await stale.delete();
    } on Object catch (e) {
      _log.warning('Could not remove a stale settings temp file: $e');
    }
    try {
      if (await file.exists()) {
        final reason = _parse(await file.readAsString(), values);
        if (reason != null) await _quarantine(file, reason);
      }
    } on Object catch (e) {
      values.clear();
      await _quarantine(file, 'unreadable: $e');
    }
    return JsonSettingsStore._(file, values, writeDelay, timerFactory);
  }

  /// Fills [into]; returns why the content is unusable, or null.
  static String? _parse(String text, Map<String, Object?> into) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return 'not JSON';
    }
    if (json is! Map<String, Object?>) return 'not an object';
    if (json['format'] != _format) return 'other format';
    final version = json['version'];
    if (version is! int || version < 1 || version > _version) return 'unsupported version $version';
    final values = json['values'];
    if (values is! Map<String, Object?>) return 'values is not an object';
    into.addAll(values);
    return null;
  }

  static Future<void> _quarantine(File file, String reason) async {
    final bad = '${file.path}.bad-${DateTime.now().millisecondsSinceEpoch}';
    _log.warning('Settings file unusable ($reason); keeping a copy at $bad');
    try {
      // Rename works for unreadable files and keeps copies from piling up.
      await file.rename(bad);
    } on Object {
      try {
        await file.copy(bad);
      } on Object catch (e) {
        _log.warning('Could not keep the unusable settings file: $e');
      }
    }
  }

  @override
  Object? read(String key) => _values[key];

  @override
  Future<void> write(String key, Object? value) async {
    final changed = value == null
        ? _values.remove(key) != null
        : !_sameJson(_values[key], value);
    if (!changed) return;
    if (value != null) _values[key] = jsonDecode(jsonEncode(value));
    _dirty = true;
    _timer ??= _timerFactory(_delay, () => unawaited(flush()));
    _changes.add(key);
  }

  static bool _sameJson(Object? a, Object? b) => jsonEncode(a) == jsonEncode(b);

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    // Chain so two flushes never write the same temp file at once.
    return _writing = _writing.then((_) => _persist());
  }

  Future<void> _persist() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await _file.parent.create(recursive: true);
      await writeFileAtomic(
        _file,
        jsonEncode({'format': _format, 'version': _version, 'values': _values}),
      );
      _failures = 0;
    } on Object catch (e, st) {
      _dirty = true;
      _log.severe('Could not save settings', e, st);
      // Bounded retry; a later write or flush also tries again.
      if (++_failures <= _maxRetries) {
        _timer ??= _timerFactory(_retryDelay, () => unawaited(flush()));
      }
    }
  }
}
