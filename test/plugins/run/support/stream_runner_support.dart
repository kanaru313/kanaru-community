import 'dart:typed_data';

import 'package:kanaru/src/plugins/data/run/fetch_judgement.dart';
import 'package:kanaru/src/plugins/data/run/stream_fetch_handler.dart';
import 'package:kanaru/src/plugins/data/run/stream_table.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

/// A stream handler without a network: an open takes a place in the run's
/// table and answers 200, a close ends it, a read ends the body.
class FakeStreamHandler implements StreamFetchHandler {
  final calls = <EngineStreamCall>[];

  @override
  Future<EngineStreamReply> handle(
    EngineStreamCall call,
    JobContext context,
    StreamTable table,
  ) async {
    calls.add(call);
    switch (call.op) {
      case EngineStreamOp.open:
        final entry = table.reserve(call.stream);
        if (entry == null) {
          return EngineStreamReply.empty(EngineFetchOutcome.network);
        }
        return EngineStreamReply(
          outcome: EngineFetchOutcome.ok,
          status: 200,
          chunk: Uint8List(0),
        );
      case EngineStreamOp.read:
        return EngineStreamReply(
          outcome: EngineFetchOutcome.ok,
          chunk: Uint8List(0),
          done: true,
        );
      case EngineStreamOp.close:
        final entry = table.find(call.stream);
        if (entry != null) table.end(entry);
        return EngineStreamReply.empty(EngineFetchOutcome.ok);
    }
  }
}
