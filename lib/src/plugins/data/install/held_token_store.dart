import 'dart:math';

import '../../domain/install/held_package.dart';

/// Tokens live this long without being taken.
const heldTokenTtl = Duration(minutes: 10);

/// Most packages held at once (two screens at most; the oldest goes first).
const maxHeldPackages = 2;

/// The packages held in memory under their tokens. Nothing here is on disk.
/// Expiry is checked on every access, so no timer runs.
class HeldTokenStore {
  HeldTokenStore({DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _clock;
  final Random _random;
  final _held = <String, ({HeldPackage package, DateTime at})>{};

  /// A fresh unguessable token (128 random bits, hex).
  String newToken() => [
    for (var i = 0; i < 16; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();

  /// Holds [package] and drops the oldest ones beyond [maxHeldPackages].
  void put(HeldPackage package) {
    _expire();
    _held[package.token] = (package: package, at: _clock());
    while (_held.length > maxHeldPackages) {
      _held.remove(_held.keys.first);
    }
  }

  /// The package under [token] without releasing it, or null when it is
  /// unknown, expired or evicted.
  HeldPackage? peek(String token) {
    _expire();
    return _held[token]?.package;
  }

  /// Releases the package under [token] for installing; null as for [peek].
  HeldPackage? take(String token) {
    _expire();
    return _held.remove(token)?.package;
  }

  /// Drops [token] (the screen was closed or the user declined).
  void discard(String token) => _held.remove(token);

  int get length {
    _expire();
    return _held.length;
  }

  void _expire() {
    final now = _clock();
    _held.removeWhere((_, v) => now.difference(v.at) >= heldTokenTtl);
  }
}
