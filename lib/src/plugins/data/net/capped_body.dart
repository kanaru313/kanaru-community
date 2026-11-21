import 'dart:io';
import 'dart:typed_data';

import '../../domain/net/fetch_failure.dart';

/// Closes the connection without reading the body.
Future<void> discardBody(HttpClientResponse response) async {
  final sub = response.listen((_) {}, onError: (_) {});
  await sub.cancel();
}

/// Reads the body of [response]. Stops and closes the connection once
/// [maxBytes] is passed (by the declared length, or as soon as one byte more
/// than the cap has arrived), throwing [FetchFailureKind.tooLarge] without
/// reading the rest. [ensureActive] runs before each chunk is kept and throws
/// when the call was stopped. [onProgress] gets the bytes so far and [total]
/// (the caller's expected size, else the declared length when there is one).
Future<Uint8List> readCappedBody(
  HttpClientResponse response,
  int maxBytes, {
  required void Function() ensureActive,
  int? total,
  void Function(int received, int? total)? onProgress,
}) async {
  final declared = response.contentLength;
  if (declared > maxBytes) {
    await discardBody(response);
    throw const FetchFailure(FetchFailureKind.tooLarge);
  }
  final knownTotal = total ?? (declared >= 0 ? declared : null);
  final out = BytesBuilder(copy: false);
  // Leaving the loop cancels the subscription and closes the connection.
  await for (final chunk in response) {
    ensureActive();
    out.add(chunk);
    if (out.length > maxBytes) {
      throw const FetchFailure(FetchFailureKind.tooLarge);
    }
    onProgress?.call(out.length, knownTotal);
  }
  return out.takeBytes();
}
