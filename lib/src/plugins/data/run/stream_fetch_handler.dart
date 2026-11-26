import 'dart:async';
import 'dart:typed_data';

import '../../../foundation/result.dart';
import '../../domain/run/plugin_engine.dart';
import '../net/plugin_http.dart';
import '../net/plugin_http_stream.dart';
import 'fetch_judgement.dart';
import 'plugin_limiter.dart';
import 'stream_table.dart';

/// Answers the stream calls (open, read, close) of one run. Never throws:
/// every failure is a reply with the matching outcome.
///
/// An open is judged and recorded exactly like a one-shot fetch (see
/// [judgeFetch], [recordFetch]); reads and closes only act on streams the
/// open put in the run's [StreamTable].
class StreamFetchHandler {
  StreamFetchHandler({required this._http, required this._limiter});

  final PluginHttpStreamClient _http;
  final PluginLimiter _limiter;

  Future<EngineStreamReply> handle(
    EngineStreamCall call,
    JobContext context,
    StreamTable table,
  ) async {
    try {
      switch (call.op) {
        case EngineStreamOp.open:
          return await _open(call, context, table);
        case EngineStreamOp.read:
          return await _read(call, table);
        case EngineStreamOp.close:
          return _close(call, table);
      }
    } on Object catch (error) {
      return EngineStreamReply.empty(unexpectedFetchFailure(error));
    }
  }

  /// Answered at once; the abort runs after the answer, so a slow socket
  /// never holds up the runtime's short close grace.
  EngineStreamReply _close(EngineStreamCall call, StreamTable table) {
    final entry = table.find(call.stream);
    if (entry != null) {
      // Reads of the id fail from here on; the abort follows the answer.
      table.release(entry);
      scheduleMicrotask(() => table.end(entry));
    }
    return EngineStreamReply.empty(EngineFetchOutcome.ok);
  }

  Future<EngineStreamReply> _open(
    EngineStreamCall call,
    JobContext context,
    StreamTable table,
  ) async {
    final request = call.request;
    if (request == null) {
      return EngineStreamReply.empty(EngineFetchOutcome.invalidRequest);
    }
    final clock = Stopwatch()..start();
    // Reserve before the first await: a Close arriving next finds the entry.
    final entry = table.reserve(call.stream);
    EngineStreamReply reply;
    if (entry == null) {
      // Sealed: the run ended. Full or duplicate id: the runtime broke its cap.
      reply = EngineStreamReply.empty(
        table.isSealed
            ? EngineFetchOutcome.network
            : EngineFetchOutcome.invalidRequest,
      );
    } else {
      try {
        reply = await _openEntry(call, request, context, table, entry, clock);
      } on Object catch (error) {
        table.end(entry);
        reply = EngineStreamReply.empty(unexpectedFetchFailure(error));
      }
    }
    recordFetch(
      request,
      context,
      reply.outcome,
      reply.status,
      clock.elapsedMilliseconds,
    );
    return reply;
  }

  Future<EngineStreamReply> _openEntry(
    EngineStreamCall call,
    EngineFetchRequest request,
    JobContext context,
    StreamTable table,
    StreamEntry entry,
    Stopwatch clock,
  ) async {
    final judged = await judgeFetch(
      request,
      context,
      _limiter,
      cancel: entry.cancel,
    );
    switch (judged) {
      case RefusedFetch(:final outcome):
        table.end(entry);
        return EngineStreamReply.empty(outcome);
      case AllowedFetch():
        break;
    }
    // The run's remaining time counts from the call, spacing wait included.
    final lifetime = call.lifetimeMs > 0
        ? Duration(milliseconds: call.lifetimeMs) - clock.elapsed
        : null;
    final answer = await _http.open(
      PluginHttpRequest(
        method: judged.method,
        url: judged.url,
        headers: judged.headers,
        body: judged.body,
      ),
      deadline: judged.timeLeft,
      cancel: entry.cancel,
      lifetime: lifetime,
    );
    switch (answer) {
      case Err(:final error):
        table.end(entry);
        return EngineStreamReply.empty(_outcomeOf(error));
      case Ok(:final value):
        // Sealed or closed while the head was arriving: nobody wants it.
        if (table.isSealed || entry.isClosed) {
          unawaited(value.close());
          table.end(entry);
          return EngineStreamReply.empty(EngineFetchOutcome.network);
        }
        entry.handle = value;
        noteResponse(
          context,
          PluginHttpResponse(
            status: value.status,
            headers: value.headers,
            body: Uint8List(0),
          ),
        );
        return EngineStreamReply(
          outcome: EngineFetchOutcome.ok,
          status: value.status,
          // Nothing is followed: the requested URL is also the final one.
          url: request.url,
          headers: value.headers,
          chunk: Uint8List(0),
          sends: 1,
        );
    }
  }

  Future<EngineStreamReply> _read(
    EngineStreamCall call,
    StreamTable table,
  ) async {
    final entry = table.find(call.stream);
    final handle = entry?.handle;
    if (entry == null || entry.isClosed || handle == null) {
      return EngineStreamReply.empty(EngineFetchOutcome.network);
    }
    final answer = await handle.read(
      maxBytes: call.maxBytes,
      wait: Duration(milliseconds: call.waitMs),
    );
    switch (answer) {
      case Err(:final error):
        // The handle has released its socket; the runtime closes the stream.
        return EngineStreamReply.empty(_outcomeOf(error));
      case Ok(:final value):
        if (value.done) {
          // A real end: Dart closes the stream, the slot is free again.
          table.end(entry);
          return EngineStreamReply(
            outcome: EngineFetchOutcome.ok,
            chunk: Uint8List(0),
            done: true,
          );
        }
        if (value.isIdle) {
          // The runtime reads idle as `network`: no empty `ok` chunk.
          return EngineStreamReply.empty(EngineFetchOutcome.network);
        }
        return EngineStreamReply(
          outcome: EngineFetchOutcome.ok,
          chunk: value.bytes,
        );
    }
  }

  static EngineFetchOutcome _outcomeOf(PluginHttpFailure failure) =>
      switch (failure) {
        PluginHttpFailure.blockedAddress => EngineFetchOutcome.blockedHost,
        PluginHttpFailure.tooLarge => EngineFetchOutcome.invalidResponse,
        PluginHttpFailure.cancelled => EngineFetchOutcome.abandoned,
        PluginHttpFailure.network ||
        PluginHttpFailure.timeout => EngineFetchOutcome.network,
      };
}
