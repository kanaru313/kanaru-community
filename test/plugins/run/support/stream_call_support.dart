import 'dart:typed_data';

import 'package:kanaru/src/plugins/data/run/fetch_judgement.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

import 'fetch_judgement_cases.dart';

/// A job snapshot for the stream handler tests.
JobContext streamJob({
  RunCancel? cancel,
  Set<String> manifest = const {judgementHost},
  Set<String> consented = const {judgementHost},
  Set<String> endpoints = const {},
}) => JobContext(
  installId: judgementInstallId,
  job: 1,
  cancel: cancel ?? RunCancel(),
  manifestHosts: manifest,
  consentedHosts: consented,
  userEndpoints: endpoints,
);

/// An `open` call for [url].
EngineStreamCall openCall(
  int id,
  String url, {
  String installId = judgementInstallId,
  List<(String, String)> headers = const [],
  int deadlineMs = 5000,
  int lifetimeMs = 60000,
}) => EngineStreamCall(
  installId: installId,
  stream: id,
  op: EngineStreamOp.open,
  lifetimeMs: lifetimeMs,
  request: EngineFetchRequest(
    installId: installId,
    method: 'GET',
    url: url,
    headers: headers,
    body: Uint8List(0),
    deadlineMs: deadlineMs,
    maxSends: 10,
  ),
);

EngineStreamCall readCall(int id, {int maxBytes = 65536, int waitMs = 2000}) =>
    EngineStreamCall(
      installId: judgementInstallId,
      stream: id,
      op: EngineStreamOp.read,
      maxBytes: maxBytes,
      waitMs: waitMs,
    );

EngineStreamCall closeCall(int id) => EngineStreamCall(
  installId: judgementInstallId,
  stream: id,
  op: EngineStreamOp.close,
);
