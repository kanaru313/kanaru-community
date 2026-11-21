import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/net/fetcher.dart';
import 'package:kanaru/src/plugins/data/net/pinned_http.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';
import 'package:kanaru/src/plugins/domain/net/net_policy.dart';

import 'net_test_support.dart';

void main() {
  late TestServer plain;
  late TestServer tls;
  late RecordingDialer dialer;
  late FakeResolver resolver;

  setUp(() async {
    plain = await TestServer.start();
    tls = await TestServer.start(secure: true);
    // Public addresses go to the TLS server, everything else dials as asked.
    dialer = RecordingDialer(
      (a, port) => a.address == fakePublicIp ? tls.port : port,
    );
    resolver = FakeResolver({
      'repo.example.test': [fakePublicIp],
      'mixed.test': [fakePublicIp, '10.0.0.1'],
      'inner.test': ['10.1.2.3'],
    });
  });

  tearDown(() async {
    await plain.close();
    await tls.close();
  });

  HttpFetcher fetcher({
    Duration connect = const Duration(seconds: 5),
    Duration total = const Duration(seconds: 10),
    SocketDialer? dial,
    HostResolver? resolve,
    String userAgent = 'Kanaru/test (+https://example.test)',
  }) => HttpFetcher(
    resolver: resolve ?? resolver.call,
    dialer: dial ?? dialer.call,
    context: trustingTestCert(),
    connectLimit: connect,
    totalLimit: total,
    userAgent: userAgent,
  );

  FetchFailure failure(Result<FetchResult, FetchFailure> r) => switch (r) {
    Err(:final error) => error,
    Ok() => fail('expected a failure'),
  };

  FetchResult success(Result<FetchResult, FetchFailure> r) => switch (r) {
    Ok(:final value) => value,
    Err(:final error) => fail('expected success, got $error'),
  };

  Future<void> redirect(HttpRequest r, String location) async {
    r.response.statusCode = 302;
    r.response.headers.set(HttpHeaders.locationHeader, location);
    await r.response.close();
  }

  Future<void> body(HttpRequest r, String text) async {
    r.response.write(text);
    await r.response.close();
  }

  Uri local(String path) => Uri.parse('http://127.0.0.1:${plain.port}$path');
  Uri pub(String path) =>
      Uri.parse('https://repo.example.test:${tls.port}$path');

  group('addresses', () {
    test(
      'a local repository over http is fetched and sends the user agent',
      () async {
        plain.handler = (r) => body(r, '{"ok":true}');
        final r = success(
          await fetcher().get(local('/c.json'), NetPolicy.repo),
        );
        expect(utf8.decode(r.bytes), '{"ok":true}');
        expect(r.kind, AddressKind.local);
        expect(r.finalUrl, local('/c.json'));
        expect(plain.userAgents.single, 'Kanaru/test (+https://example.test)');
      },
    );

    test('a public repository connects to the checked address and verifies '
        'the host name over TLS', () async {
      tls.handler = (r) => body(r, 'catalog');
      final r = success(await fetcher().get(pub('/c.json'), NetPolicy.repo));
      expect(utf8.decode(r.bytes), 'catalog');
      expect(r.kind, AddressKind.public);
      expect(dialer.dialed.map((a) => a.address), [fakePublicIp]);
      expect(resolver.lookups, ['repo.example.test']);
    });

    test('an untrusted certificate fails the connection', () async {
      final f = HttpFetcher(resolver: resolver.call, dialer: dialer.call);
      final e = failure(await f.get(pub('/c.json'), NetPolicy.repo));
      expect(e.kind, FetchFailureKind.network);
      expect(tls.requests, isEmpty);
    });

    test(
      'a public name over plain http is refused before any connection',
      () async {
        final e = failure(
          await fetcher().get(
            Uri.parse('http://repo.example.test/c.json'),
            NetPolicy.repo,
          ),
        );
        expect(e.kind, FetchFailureKind.blockedAddress);
        expect(e.reason, AddressProblem.publicNeedsHttps);
        expect(dialer.dialed, isEmpty);
      },
    );

    test('a mixed answer is refused and nothing is dialed', () async {
      final e = failure(
        await fetcher().get(
          Uri.parse('https://mixed.test/c.json'),
          NetPolicy.repo,
        ),
      );
      expect(e.kind, FetchFailureKind.blockedAddress);
      expect(e.reason, AddressProblem.mixedAddresses);
      expect(dialer.dialed, isEmpty);
    });

    test(
      'a public catalog may not point to a name that resolves locally',
      () async {
        final e = failure(
          await fetcher().get(
            Uri.parse('https://inner.test/p.zip'),
            NetPolicy.package,
            catalogKind: AddressKind.public,
          ),
        );
        expect(e.reason, AddressProblem.localFromPublic);
        expect(dialer.dialed, isEmpty);
      },
    );

    test('a package of a local catalog may be local', () async {
      plain.handler = (r) => body(r, 'zip');
      final r = success(
        await fetcher().get(
          local('/p.zip'),
          NetPolicy.package,
          catalogKind: AddressKind.local,
        ),
      );
      expect(utf8.decode(r.bytes), 'zip');
    });

    test('a package without a catalog kind is judged as public', () async {
      final e = failure(
        await fetcher().get(local('/p.zip'), NetPolicy.package),
      );
      expect(e.reason, AddressProblem.localFromPublic);
    });

    test('user info and non-http schemes are refused', () async {
      var e = failure(
        await fetcher().get(
          Uri.parse('https://u:p@repo.example.test/c.json'),
          NetPolicy.repo,
        ),
      );
      expect(e.reason, AddressProblem.userInfo);
      e = failure(
        await fetcher().get(Uri.parse('ftp://x.test/c'), NetPolicy.repo),
      );
      expect(e.kind, FetchFailureKind.invalidUrl);
      expect(dialer.dialed, isEmpty);
    });
  });

  group('redirects', () {
    test('three are followed, the fourth is refused', () async {
      plain.handler = (r) async {
        final n = int.parse(r.uri.pathSegments.last);
        if (n < 3) return redirect(r, '/r/${n + 1}');
        await body(r, 'end');
      };
      final r = success(await fetcher().get(local('/r/0'), NetPolicy.repo));
      expect(r.finalUrl, local('/r/3'));

      plain.handler = (r) async {
        final n = int.parse(r.uri.pathSegments.last);
        await redirect(r, '/r/${n + 1}');
      };
      final e = failure(await fetcher().get(local('/r/0'), NetPolicy.repo));
      expect(e.kind, FetchFailureKind.network);
    });

    test(
      'a redirect from a public origin to the local network is refused',
      () async {
        for (final target in [
          'https://10.0.0.1/x',
          'http://127.0.0.1:${plain.port}/x',
          'https://inner.test/x',
          'https://localhost/x',
          'https://[::1]/x',
        ]) {
          tls.handler = (r) => redirect(r, target);
          final e = failure(
            await fetcher().get(pub('/c.json'), NetPolicy.repo),
          );
          expect(e.kind, FetchFailureKind.blockedAddress, reason: target);
          expect(e.reason, AddressProblem.localFromPublic, reason: target);
        }
        expect(plain.requests, isEmpty);
        expect(dialer.dialed.map((a) => a.address).toSet(), {fakePublicIp});
      },
    );

    test('a redirect from a public origin to plain http is refused', () async {
      tls.handler = (r) => redirect(r, 'http://repo.example.test/x');
      final e = failure(await fetcher().get(pub('/c.json'), NetPolicy.repo));
      expect(e.reason, AddressProblem.publicNeedsHttps);
    });

    test(
      'a local origin that hops through a public host cannot go back',
      () async {
        plain.handler = (r) => redirect(r, pub('/hop').toString());
        tls.handler = (r) => redirect(r, local('/back').toString());
        final e = failure(
          await fetcher().get(local('/c.json'), NetPolicy.repo),
        );
        expect(e.reason, AddressProblem.localFromPublic);
        expect(plain.requests, hasLength(1));
      },
    );

    test('a local origin may redirect to local, and to public https', () async {
      plain.handler = (r) async {
        if (r.uri.path == '/c.json') return redirect(r, '/moved.json');
        await redirect(r, pub('/final').toString());
      };
      tls.handler = (r) => body(r, 'done');
      final r = success(await fetcher().get(local('/c.json'), NetPolicy.repo));
      expect(utf8.decode(r.bytes), 'done');
      expect(r.kind, AddressKind.public);
    });

    test('a redirect without a usable Location fails', () async {
      plain.handler = (r) async {
        r.response.statusCode = 302;
        await r.response.close();
      };
      final e = failure(await fetcher().get(local('/c.json'), NetPolicy.repo));
      expect(e.kind, FetchFailureKind.network);
    });
  });

  group('status', () {
    test('a non-2xx answer is a bad status', () async {
      for (final code in [404, 410, 500]) {
        plain.handler = (r) async {
          r.response.statusCode = code;
          await r.response.close();
        };
        final e = failure(
          await fetcher().get(local('/c.json'), NetPolicy.repo),
        );
        expect(e.kind, FetchFailureKind.badStatus);
        expect(e.status, code);
      }
    });
  });

  group('caps', () {
    test('a body of exactly the cap passes', () async {
      plain.handler = (r) => body(r, 'a' * 1000);
      final r = success(
        await fetcher().get(local('/c'), NetPolicy.repo, maxBytes: 1000),
      );
      expect(r.bytes, hasLength(1000));
    });

    test('a declared length over the cap is refused without reading', () async {
      plain.handler = (r) async {
        r.response.contentLength = 1001;
        r.response.add(List.filled(10, 1));
        await r.response.flush();
        await Future<void>.delayed(const Duration(seconds: 2));
      };
      final watch = Stopwatch()..start();
      final e = failure(
        await fetcher().get(local('/c'), NetPolicy.repo, maxBytes: 1000),
      );
      expect(e.kind, FetchFailureKind.tooLarge);
      expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('a streamed body stops one byte past the cap and the rest is not '
        'read', () async {
      var chunksSent = 0;
      plain.handler = (r) async {
        // Chunked: no declared length. 100 chunks of 100 bytes, slowly.
        // Without this the server holds small writes back until 8 KiB.
        r.response.bufferOutput = false;
        var gone = false;
        unawaited(r.response.done.then((_) {}, onError: (_) => gone = true));
        for (var i = 0; i < 100 && !gone; i++) {
          r.response.add(List.filled(100, 7));
          await r.response.flush();
          chunksSent++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await r.response.close();
      };
      final e = failure(
        await fetcher().get(local('/c'), NetPolicy.repo, maxBytes: 250),
      );
      expect(e.kind, FetchFailureKind.tooLarge);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // The server was cut off long before it sent everything.
      expect(chunksSent, lessThan(60));
    });

    test('the policy cap applies when the caller gives none', () async {
      plain.handler = (r) => body(r, 'a' * (64 * 1024 + 1));
      final e = failure(
        await fetcher().get(
          local('/i.png'),
          NetPolicy.icon,
          catalogKind: AddressKind.local,
        ),
      );
      expect(e.kind, FetchFailureKind.tooLarge);
      // A larger override never raises the cap.
      final again = failure(
        await fetcher().get(
          local('/i.png'),
          NetPolicy.icon,
          catalogKind: AddressKind.local,
          maxBytes: 10 * 1024 * 1024,
        ),
      );
      expect(again.kind, FetchFailureKind.tooLarge);
    });
  });

  group('progress', () {
    test('reports bytes and the declared length', () async {
      plain.handler = (r) async {
        r.response.contentLength = 300;
        r.response.add(List.filled(300, 1));
        await r.response.close();
      };
      final seen = <(int, int?)>[];
      success(
        await fetcher().get(
          local('/p.zip'),
          NetPolicy.link,
          onProgress: (got, total) => seen.add((got, total)),
        ),
      );
      expect(seen, isNotEmpty);
      expect(seen.last, (300, 300));
    });

    test('the caller-provided size wins over the declared length', () async {
      plain.handler = (r) => body(r, 'abc');
      final seen = <(int, int?)>[];
      success(
        await fetcher().get(
          local('/p.zip'),
          NetPolicy.link,
          expectedSize: 3,
          onProgress: (got, total) => seen.add((got, total)),
        ),
      );
      expect(seen.last, (3, 3));
    });
  });

  group('time limits and cancel', () {
    /// A raw server that answers with a header and one body byte, then hangs.
    Future<(ServerSocket, Completer<void>)> stallingServer() async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close());
      final closed = Completer<void>();
      server.listen((socket) {
        socket.listen(
          (_) {
            socket.write('HTTP/1.1 200 OK\r\ncontent-length: 100\r\n\r\nx');
          },
          onDone: () {
            if (!closed.isCompleted) closed.complete();
          },
          onError: (_) {
            if (!closed.isCompleted) closed.complete();
          },
        );
      });
      return (server, closed);
    }

    test(
      'a slow body ends at the total limit and the socket is closed',
      () async {
        final (server, closed) = await stallingServer();
        final watch = Stopwatch()..start();
        final e = failure(
          await fetcher(total: const Duration(milliseconds: 400)).get(
            Uri.parse('http://127.0.0.1:${server.port}/c.json'),
            NetPolicy.repo,
          ),
        );
        expect(e.kind, FetchFailureKind.timeout);
        expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
        await closed.future.timeout(const Duration(seconds: 5));
      },
    );

    test('a connection that never opens ends at the connect limit and is '
        'cancelled', () async {
      final hanging = HangingDialer();
      final watch = Stopwatch()..start();
      final e = failure(
        await fetcher(
          connect: const Duration(milliseconds: 100),
          dial: hanging.call,
        ).get(pub('/c.json'), NetPolicy.repo),
      );
      expect(e.kind, FetchFailureKind.timeout);
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
      expect(hanging.dialed, 1);
      expect(hanging.cancelled, greaterThanOrEqualTo(1));
    });

    test(
      'a lookup that ends after the total limit starts no connection',
      () async {
        final late = Completer<List<InternetAddress>>();
        final hanging = HangingDialer();
        final e = failure(
          await fetcher(
            total: const Duration(milliseconds: 100),
            resolve: (_) => late.future,
            dial: hanging.call,
          ).get(pub('/c.json'), NetPolicy.repo),
        );
        expect(e.kind, FetchFailureKind.timeout);
        late.complete([InternetAddress(fakePublicIp)]);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(hanging.dialed, 0);
        expect(tls.requests, isEmpty);
      },
    );

    test('no hop starts after the total limit', () async {
      var hops = 0;
      plain.handler = (r) async {
        hops++;
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await redirect(r, '/next');
      };
      final e = failure(
        await fetcher(total: const Duration(milliseconds: 200))
            .get(local('/c.json'), NetPolicy.repo),
      );
      expect(e.kind, FetchFailureKind.timeout);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(hops, lessThanOrEqualTo(2));
      expect(plain.requests.length, hops);
    });

    test('cancel stops a fetch in flight and closes the socket', () async {
      final (server, closed) = await stallingServer();
      final token = CancelToken();
      final pending = fetcher().get(
        Uri.parse('http://127.0.0.1:${server.port}/c.json'),
        NetPolicy.repo,
        cancel: token,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      token.cancel();
      expect(failure(await pending).kind, FetchFailureKind.cancelled);
      await closed.future.timeout(const Duration(seconds: 5));
    });

    test('a token cancelled before the call does no work', () async {
      final token = CancelToken()..cancel();
      final e = failure(
        await fetcher().get(pub('/c.json'), NetPolicy.repo, cancel: token),
      );
      expect(e.kind, FetchFailureKind.cancelled);
      expect(resolver.lookups, isEmpty);
      expect(dialer.dialed, isEmpty);
    });
  });

  group('connection details', () {
    test(
      'a certificate that does not cover the host name is refused',
      () async {
        resolver.answers['other.test'] = [fakePublicIp];
        final e = failure(
          await fetcher().get(
            Uri.parse('https://other.test:${tls.port}/c.json'),
            NetPolicy.repo,
          ),
        );
        expect(e.kind, FetchFailureKind.network);
        expect(tls.requests, isEmpty);
      },
    );

    test(
      'a lookup that uses the whole connect budget is a connect timeout',
      () async {
        final factory = pinnedConnectionFactory(
          check: (_, _) {},
          resolver: (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 45));
            return [InternetAddress(fakePublicIp)];
          },
          dialer: HangingDialer().call,
          connectTimeout: const Duration(milliseconds: 50),
        );
        final task = await factory(Uri.parse('https://x.test/'), null, null);
        await expectLater(task.socket, throwsA(isA<ConnectTimeout>()));
      },
    );

    test('the connection factory refuses a proxy', () async {
      final factory = pinnedConnectionFactory(check: (_, _) {});
      await expectLater(
        factory(Uri.parse('http://example.test/'), 'proxy', 3128),
        throwsA(isA<SocketException>()),
      );
    });

    test('the next address is tried when the first dial fails', () async {
      resolver.answers['repo.example.test'] = ['93.184.216.35', fakePublicIp];
      final asked = <String>[];
      Future<ConnectionTask<Socket>> dial(InternetAddress a, int port) {
        asked.add(a.address);
        if (a.address == '93.184.216.35') {
          throw const SocketException('refused');
        }
        return dialer.call(a, port);
      }

      tls.handler = (r) => body(r, 'second');
      final r = success(
        await fetcher(dial: dial).get(pub('/c.json'), NetPolicy.repo),
      );
      expect(utf8.decode(r.bytes), 'second');
      expect(asked, ['93.184.216.35', fakePublicIp]);
    });
  });

  group('cancel token', () {
    test(
      'a token shared by many calls keeps no listener after they end',
      () async {
        final token = CancelToken();
        plain.handler = (r) => body(r, 'x');
        for (var i = 0; i < 5; i++) {
          success(
            await fetcher().get(local('/c'), NetPolicy.repo, cancel: token),
          );
          expect(token.listenerCount, 0);
        }
        plain.handler = (r) async {
          r.response.statusCode = 500;
          await r.response.close();
        };
        failure(
          await fetcher().get(local('/c'), NetPolicy.repo, cancel: token),
        );
        expect(token.listenerCount, 0);
        token.cancel();
      },
    );
  });

  test('a refused connection is a network failure, not an exception', () async {
    final closedPort = plain.port;
    await plain.close();
    final e = failure(
      await fetcher().get(
        Uri.parse('http://127.0.0.1:$closedPort/c.json'),
        NetPolicy.repo,
      ),
    );
    expect(e.kind, FetchFailureKind.network);
  });
}
