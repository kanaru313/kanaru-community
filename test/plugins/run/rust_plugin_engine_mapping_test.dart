import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/rust_plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/rust/api/plugin_runtime.dart' as rust;
import 'package:kanaru/src/rust/api/plugin_stream.dart' as rust;

void main() {
  test('open call keeps the request and lifetime', () {
    final call = streamCallFromBridge(
      rust.PluginStreamCall(
        installId: 'p',
        stream: 3,
        op: rust.PluginStreamOp.open,
        request: rust.PluginFetchRequest(
          installId: 'p',
          method: 'POST',
          url: 'https://a.example/x',
          headers: const [('k', 'v')],
          body: Uint8List.fromList([9]),
          deadlineMs: 500,
          maxSends: 2,
        ),
        maxBytes: 0,
        waitMs: 0,
        lifetimeMs: 70000,
      ),
    );
    expect(call.op, EngineStreamOp.open);
    expect(call.stream, 3);
    expect(call.lifetimeMs, 70000);
    expect(call.request!.url, 'https://a.example/x');
    expect(call.request!.headers, [('k', 'v')]);
    expect(call.request!.maxSends, 2);
  });

  test('read and close calls map their op and limits', () {
    rust.PluginStreamCall bridge(rust.PluginStreamOp op) =>
        rust.PluginStreamCall(
          installId: 'p',
          stream: 4,
          op: op,
          maxBytes: 100,
          waitMs: 250,
          lifetimeMs: 0,
        );
    final read = streamCallFromBridge(bridge(rust.PluginStreamOp.read));
    expect(read.op, EngineStreamOp.read);
    expect(read.maxBytes, 100);
    expect(read.waitMs, 250);
    expect(read.request, isNull);
    expect(
      streamCallFromBridge(bridge(rust.PluginStreamOp.close)).op,
      EngineStreamOp.close,
    );
  });

  test('replies map outcome, head and chunk', () {
    final open = streamReplyToBridge(
      EngineStreamReply(
        outcome: EngineFetchOutcome.rateLimited,
        status: 429,
        url: 'u',
        headers: [('a', 'b')],
        retryAfterSec: 7,
        chunk: Uint8List(0),
        sends: 2,
      ),
    );
    expect(open.outcome, rust.PluginFetchOutcome.rateLimited);
    expect(open.status, 429);
    expect(open.retryAfterSec, 7);
    expect(open.sends, 2);
    expect(open.headers, [('a', 'b')]);

    final read = streamReplyToBridge(
      EngineStreamReply(
        outcome: EngineFetchOutcome.ok,
        chunk: Uint8List.fromList([1, 2]),
        done: true,
      ),
    );
    expect(read.chunk, [1, 2]);
    expect(read.done, isTrue);

    final close = streamReplyToBridge(
      EngineStreamReply.empty(EngineFetchOutcome.ok),
    );
    expect(close.outcome, rust.PluginFetchOutcome.ok);
    expect(close.chunk, isEmpty);
  });
}
