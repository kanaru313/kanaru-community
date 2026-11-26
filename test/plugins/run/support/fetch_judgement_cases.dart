import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

/// Install id of the job every case runs under.
const judgementInstallId = 'plug-1';

/// The manifest host the cases use.
const judgementHost = 'repo.example.test';

/// One request, the run snapshot it is judged against and the verdict the
/// shared fetch rules must give. A `null` [expected] means the request may be
/// sent. Every network path of a plugin run (one-shot fetch, stream open) must
/// agree with this table.
class FetchJudgementCase {
  const FetchJudgementCase(
    this.name,
    this.url, {
    this.expected,
    this.installId = judgementInstallId,
    this.headers = const [],
    this.manifest = const {judgementHost},
    this.consented = const {judgementHost},
    this.endpoints = const {},
  });

  final String name;
  final String url;
  final EngineFetchOutcome? expected;
  final String installId;
  final List<(String, String)> headers;
  final Set<String> manifest;
  final Set<String> consented;
  final Set<String> endpoints;
}

const fetchJudgementCases = <FetchJudgementCase>[
  FetchJudgementCase('manifest host consented', 'https://repo.example.test/a'),
  FetchJudgementCase(
    'manifest host not consented',
    'https://repo.example.test/a',
    consented: {'other.example.test'},
    expected: EngineFetchOutcome.blockedHost,
  ),
  FetchJudgementCase(
    'no consented host at all',
    'https://repo.example.test/a',
    consented: {},
    expected: EngineFetchOutcome.notConsented,
  ),
  FetchJudgementCase(
    'host not declared by the manifest',
    'https://unlisted.example.test/a',
    expected: EngineFetchOutcome.blockedHost,
  ),
  FetchJudgementCase(
    'user url endpoint with a port',
    'https://my.server.example:8443/api',
    endpoints: {'https://my.server.example:8443'},
  ),
  FetchJudgementCase(
    'user url endpoint on another port',
    'https://my.server.example:9000/api',
    endpoints: {'https://my.server.example:8443'},
    expected: EngineFetchOutcome.blockedHost,
  ),
  FetchJudgementCase(
    'ip literal',
    'https://93.184.216.34/',
    expected: EngineFetchOutcome.blockedHost,
  ),
  FetchJudgementCase(
    'plain http',
    'http://repo.example.test/a',
    expected: EngineFetchOutcome.blockedHost,
  ),
  FetchJudgementCase(
    'not a url',
    'not a url',
    expected: EngineFetchOutcome.invalidRequest,
  ),
  FetchJudgementCase(
    'header value with a line break',
    'https://repo.example.test/a',
    headers: [('x-a', 'a\r\nb: c')],
    expected: EngineFetchOutcome.invalidRequest,
  ),
  FetchJudgementCase(
    'header name that is not a token',
    'https://repo.example.test/a',
    headers: [('bad name', 'x')],
    expected: EngineFetchOutcome.invalidRequest,
  ),
  FetchJudgementCase(
    'host owned header is dropped, request stays allowed',
    'https://repo.example.test/a',
    headers: [('host', 'evil.example.test')],
  ),
  FetchJudgementCase(
    'install id of another plugin',
    'https://repo.example.test/a',
    installId: 'other',
    expected: EngineFetchOutcome.invalidRequest,
  ),
];
