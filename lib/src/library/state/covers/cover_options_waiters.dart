import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../shown_cover_provider.dart';

/// The first value of [provider], read through a listener that lives as long
/// as the options provider, so the source is not rebuilt meanwhile.
Future<T> firstAsync<T>(Ref ref, ProviderListenable<AsyncValue<T>> provider) {
  final done = Completer<T>();
  ref.listen<AsyncValue<T>>(provider, (_, next) {
    if (done.isCompleted) return;
    if (next.hasValue) {
      done.complete(next.value as T);
    } else if (next.hasError) {
      done.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);
  return done.future;
}

Future<ShownCover> firstSettled(
  Ref ref,
  ProviderListenable<ShownCover> provider,
) {
  final done = Completer<ShownCover>();
  ref.listen<ShownCover>(provider, (_, next) {
    if (!done.isCompleted && next is! ShownCoverLoading) done.complete(next);
  }, fireImmediately: true);
  return done.future;
}
