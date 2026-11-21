import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/plugins/data/net/fetcher.dart';
import 'package:kanaru/src/plugins/domain/install/script_checker.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';
import 'package:kanaru/src/plugins/domain/net/net_policy.dart';

import '../fixtures/catalog_support.dart';

/// One request the fake fetcher saw.
class FetchCall {
  FetchCall(this.uri, this.policy, this.catalogKind);

  final Uri uri;
  final NetPolicy policy;
  final AddressKind? catalogKind;
}

typedef FetchAnswer = Future<Result<FetchResult, FetchFailure>> Function(
  Uri uri,
);

/// A fetcher that answers from a function and records its calls.
class FakeFetcher implements HttpFetcher {
  FakeFetcher(this.answer);

  FetchAnswer answer;
  final calls = <FetchCall>[];
  var running = 0;
  var maxRunning = 0;

  @override
  Future<Result<FetchResult, FetchFailure>> get(
    Uri uri,
    NetPolicy policy, {
    AddressKind? catalogKind,
    int? maxBytes,
    int? expectedSize,
    CancelToken? cancel,
    void Function(int received, int? total)? onProgress,
  }) async {
    calls.add(FetchCall(uri, policy, catalogKind));
    running++;
    if (running > maxRunning) maxRunning = running;
    try {
      final pending = answer(uri);
      if (cancel == null) return await pending;
      // Like the real fetcher, a cancel ends the call at once.
      final cancelled = Completer<Result<FetchResult, FetchFailure>>();
      final unlisten = cancel.listen(
        () => cancelled.complete(
          const Err(FetchFailure(FetchFailureKind.cancelled)),
        ),
      );
      try {
        return await Future.any([pending, cancelled.future]);
      } finally {
        unlisten();
      }
    } finally {
      running--;
    }
  }
}

/// A successful answer with [bytes] as if fetched from [url].
Result<FetchResult, FetchFailure> served(
  Uint8List bytes, {
  Uri? url,
  AddressKind kind = AddressKind.public,
}) => Ok(FetchResult(bytes: bytes, finalUrl: url ?? catalogUrl, kind: kind));

Result<FetchResult, FetchFailure> failed(
  FetchFailureKind kind, {
  AddressProblem? reason,
}) => Err(
  kind == FetchFailureKind.blockedAddress
      ? FetchFailure.blocked(reason!)
      : FetchFailure(kind),
);

/// A catalog with one entry per [slugs] (name, version 3, host of the lyrics
/// demo); [over] changes every entry.
Uint8List catalogBytes(
  List<String> slugs, {
  Map<String, Object?> over = const {},
}) => jsonBytes(
  catalogJson([
    for (final slug in slugs)
      entryJson({
        'slug': slug,
        'name': 'Plugin $slug',
        'path': 'https://cdn.example.com/$slug/plugin.zip',
        'icon': 'https://cdn.example.com/$slug/icon.png',
        'hosts': ['music.example.com'],
        ...over,
      }),
  ]),
);

/// A checker that reports problems for chosen files and records the files it
/// was asked about.
class FakeChecker implements ScriptChecker {
  final problems = <String, ScriptProblem>{};
  final checked = <String>[];
  Object? throwWith;
  Duration delay = Duration.zero;

  @override
  Future<ScriptProblem?> check(String fileName, String source) async {
    checked.add(fileName);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throwWith != null) throw throwWith!;
    return problems[fileName];
  }
}

/// A picker that only reads: [reader] gives the result per document.
class FakePicker implements DocumentPicker {
  FakePicker(this.reader);

  Future<Result<Uint8List, DocumentError>> Function(
    PickedDocument doc,
    int maxBytes,
  )
  reader;

  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) => reader(doc, maxBytes);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

PickedDocument pickedZip([String name = 'plugin.zip']) =>
    PickedDocument(name: name, handle: '/tmp/$name');

/// A temp folder for one test; delete it in `tearDown`.
Directory tempDir() => Directory.systemTemp.createTempSync('kanaru-plugins-');

InternetAddress publicIp() => InternetAddress('93.184.216.34');
InternetAddress localIp() => InternetAddress('192.168.1.10');
