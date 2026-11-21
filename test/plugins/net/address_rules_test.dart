import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/net/address_class.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/net_policy.dart';

List<int> _ip(String s) => parseIpLiteral(s)!;

void main() {
  const publicIp = '93.184.216.34';

  AddressVerdict judge(
    String url,
    List<String> ips, {
    AddressKind? catalogKind,
  }) => judgeAddress(
    Uri.parse(url),
    addresses: [for (final s in ips) _ip(s)],
    catalogKind: catalogKind,
  );

  group('classifyAddress', () {
    test('IPv4 classes', () {
      const local = [
        '10.1.2.3',
        '100.64.0.1',
        '100.127.255.255',
        '127.0.0.1',
        '169.254.1.1',
        '172.16.0.1',
        '172.31.255.255',
        '192.168.0.1',
      ];
      const refused = [
        '0.0.0.0',
        '192.0.0.1',
        '192.0.2.1',
        '192.88.99.1',
        '198.51.100.1',
        '203.0.113.1',
        '224.0.0.1',
        '240.0.0.1',
        '255.255.255.255',
      ];
      const public = [
        publicIp,
        '8.8.8.8',
        '100.63.255.255',
        '100.128.0.1',
        '172.15.0.1',
        '172.32.0.1',
        '192.169.0.1',
      ];
      for (final ip in local) {
        expect(classifyAddress(_ip(ip)), AddressClass.local, reason: ip);
      }
      for (final ip in refused) {
        expect(classifyAddress(_ip(ip)), AddressClass.refused, reason: ip);
      }
      for (final ip in public) {
        expect(classifyAddress(_ip(ip)), AddressClass.public, reason: ip);
      }
    });

    test('the fake-ip block 198.18.0.0/15 is public, not refused', () {
      // Fake-ip TUN proxies answer every lookup from this block; refusing it
      // would break every public repository for those users.
      expect(classifyAddress(_ip('198.18.0.1')), AddressClass.public);
      expect(classifyAddress(_ip('198.19.255.254')), AddressClass.public);
    });

    test('IPv6 classes', () {
      const local = ['::1', 'fc00::1', 'fd12::1', 'fe80::1', 'fec0::1'];
      const refused = [
        '::',
        '::2',
        'ff02::1',
        '2001::1',
        '2001:db8::1',
        '2002::1',
        '3fff::1',
        '64:ff9b:1::1',
        '4000::1',
      ];
      const public = ['2606:4700::1111', '2a00:1450::1', '3fff:1000::1'];
      for (final ip in local) {
        expect(classifyAddress(_ip(ip)), AddressClass.local, reason: ip);
      }
      for (final ip in refused) {
        expect(classifyAddress(_ip(ip)), AddressClass.refused, reason: ip);
      }
      for (final ip in public) {
        expect(classifyAddress(_ip(ip)), AddressClass.public, reason: ip);
      }
    });

    test('IPv4-mapped and NAT64 addresses take the IPv4 class', () {
      expect(classifyAddress(_ip('::ffff:127.0.0.1')), AddressClass.local);
      expect(classifyAddress(_ip('::ffff:10.0.0.1')), AddressClass.local);
      expect(classifyAddress(_ip('::ffff:0.0.0.0')), AddressClass.refused);
      expect(classifyAddress(_ip('::ffff:8.8.8.8')), AddressClass.public);
      expect(classifyAddress(_ip('64:ff9b::7f00:1')), AddressClass.local);
      expect(classifyAddress(_ip('64:ff9b::808:808')), AddressClass.public);
    });

    test('a wrong byte length is refused', () {
      expect(classifyAddress([1, 2, 3]), AddressClass.refused);
      expect(classifyAddress(const []), AddressClass.refused);
    });

    test('a set must agree', () {
      expect(
        classifyAddresses([_ip(publicIp), _ip('8.8.8.8')]),
        AddressClass.public,
      );
      expect(
        classifyAddresses([_ip(publicIp), _ip('10.0.0.1')]),
        AddressClass.mixed,
      );
      expect(
        classifyAddresses([_ip(publicIp), _ip('0.0.0.0')]),
        AddressClass.refused,
      );
      expect(classifyAddresses(const []), AddressClass.refused);
    });
  });

  group('names and literals', () {
    test('local host names', () {
      for (final h in [
        'localhost',
        'LOCALHOST.',
        'nas.lan',
        'a.b.local',
        'x.home.arpa',
        'svc.internal',
        'pc.localdomain',
        'app.localhost',
      ]) {
        expect(isLocalHostName(h), isTrue, reason: h);
      }
      for (final h in ['example.com', 'lan.example.com', 'notlocalhost']) {
        expect(isLocalHostName(h), isFalse, reason: h);
      }
    });

    test('IP literal parsing', () {
      expect(parseIpLiteral('10.0.0.1'), [10, 0, 0, 1]);
      expect(parseIpLiteral('::1'), hasLength(16));
      expect(parseIpLiteral('example.com'), isNull);
      expect(parseIpLiteral('999.1.1.1'), isNull);
      expect(parseIpLiteral(''), isNull);
    });
  });

  group('the repository URL the user typed', () {
    test('local destinations may use http or https, any port', () {
      for (final (url, ip) in [
        ('http://192.168.1.5:8765/plugins.json', '192.168.1.5'),
        ('https://192.168.1.5/plugins.json', '192.168.1.5'),
        ('http://localhost:8080/c.json', '127.0.0.1'),
        ('http://[::1]:9/c.json', '::1'),
        ('http://nas.lan/c.json', '10.0.0.7'),
        ('http://svc.internal/c.json', '100.64.1.1'),
        ('http://fe80.example/c.json', 'fe80::1'),
      ]) {
        final v = judge(url, [ip]);
        expect(v.isAllowed, isTrue, reason: url);
        expect(v.kind, AddressKind.local, reason: url);
      }
    });

    test('a public destination needs https', () {
      expect(
        judge('http://example.com/x.json', [publicIp]).problem,
        AddressProblem.publicNeedsHttps,
      );
      expect(
        judge('http://8.8.8.8/x.json', ['8.8.8.8']).problem,
        AddressProblem.publicNeedsHttps,
      );
      final ok = judge('https://example.com:8443/x.json', [publicIp]);
      expect(ok.isAllowed, isTrue);
      expect(ok.kind, AddressKind.public);
    });

    test('a public name that resolves to a local address counts as local', () {
      final v = judge('http://example.com/x.json', ['127.0.0.1']);
      expect(v.kind, AddressKind.local);
    });

    test('a local name that resolves to a public address is refused', () {
      expect(
        judge('https://nas.lan/x.json', [publicIp]).problem,
        AddressProblem.localNameOnPublic,
      );
    });

    test('a mixed answer is refused', () {
      expect(
        judge('https://example.com/x.json', [publicIp, '10.0.0.1']).problem,
        AddressProblem.mixedAddresses,
      );
    });

    test('refused ranges are never allowed', () {
      for (final ip in ['0.0.0.0', '224.0.0.1', '255.255.255.255', '::']) {
        expect(
          judge('http://example.com/x.json', [ip]).problem,
          AddressProblem.refusedAddress,
          reason: ip,
        );
      }
    });

    test('user info and other schemes are refused', () {
      expect(
        judge('https://user:pw@example.com/x', [publicIp]).problem,
        AddressProblem.userInfo,
      );
      expect(
        judge('https://user@192.168.1.2/x', ['192.168.1.2']).problem,
        AddressProblem.userInfo,
      );
      for (final url in ['ftp://example.com/x', 'file:///etc/passwd', '/rel']) {
        expect(
          judgeAddress(Uri.parse(url)).problem,
          AddressProblem.invalidUrl,
          reason: url,
        );
      }
    });

    test('before a lookup only the answer-independent rules apply', () {
      expect(judgeAddress(Uri.parse('http://example.com/x')).isAllowed, isTrue);
      expect(judgeAddress(Uri.parse('http://example.com/x')).kind, isNull);
      expect(
        judgeAddress(Uri.parse('http://10.0.0.1/x')).kind,
        AddressKind.local,
      );
      expect(
        judgeAddress(Uri.parse('http://0.0.0.0/x')).problem,
        AddressProblem.refusedAddress,
      );
      expect(
        judgeAddress(Uri.parse('http://nas.lan/x')).kind,
        AddressKind.local,
      );
    });
  });

  group('references inside a catalog', () {
    test('a public catalog points to public https only', () {
      const kind = AddressKind.public;
      expect(
        judge('https://cdn.example.com/p.zip', [
          publicIp,
        ], catalogKind: kind).kind,
        AddressKind.public,
      );
      expect(
        judge('http://cdn.example.com/p.zip', [
          publicIp,
        ], catalogKind: kind).problem,
        AddressProblem.publicNeedsHttps,
      );
      for (final (url, ip) in [
        ('https://cdn.example.com/p.zip', '10.0.0.1'),
        ('http://192.168.1.2/p.zip', '192.168.1.2'),
        ('https://localhost/p.zip', '127.0.0.1'),
      ]) {
        expect(
          judge(url, [ip], catalogKind: kind).problem,
          AddressProblem.localFromPublic,
          reason: url,
        );
      }
    });

    test('a local catalog may point to local addresses and public https', () {
      const kind = AddressKind.local;
      expect(
        judge('http://192.168.1.2/p.zip', [
          '192.168.1.2',
        ], catalogKind: kind).kind,
        AddressKind.local,
      );
      expect(
        judge('https://cdn.example.com/p.zip', [
          publicIp,
        ], catalogKind: kind).kind,
        AddressKind.public,
      );
      expect(
        judge('http://cdn.example.com/p.zip', [
          publicIp,
        ], catalogKind: kind).problem,
        AddressProblem.publicNeedsHttps,
      );
    });

    test('isCatalogReferenceAllowed applies the lookup-free rules', () {
      final pub = isCatalogReferenceAllowed(AddressKind.public);
      final loc = isCatalogReferenceAllowed(AddressKind.local);
      expect(pub(Uri.parse('https://cdn.example.com/p.zip')), isTrue);
      expect(pub(Uri.parse('http://cdn.example.com/p.zip')), isFalse);
      expect(pub(Uri.parse('https://10.0.0.1/p.zip')), isFalse);
      expect(pub(Uri.parse('https://nas.lan/p.zip')), isFalse);
      expect(pub(Uri.parse('https://u:p@cdn.example.com/p.zip')), isFalse);
      expect(loc(Uri.parse('http://10.0.0.1/p.zip')), isTrue);
      expect(loc(Uri.parse('http://nas.lan/p.zip')), isTrue);
      expect(loc(Uri.parse('https://cdn.example.com/p.zip')), isTrue);
      expect(loc(Uri.parse('http://cdn.example.com/p.zip')), isTrue);
    });
  });

  group('effectiveAddressKind', () {
    AddressVerdict verdict(String url, String ip) => judge(url, [ip]);

    test('the stricter of the stored and the fresh class wins', () {
      final local = verdict('http://nas.lan/c', '10.0.0.1');
      final public = verdict('https://example.com/c', publicIp);
      expect(effectiveAddressKind(AddressKind.local, local), AddressKind.local);
      expect(
        effectiveAddressKind(AddressKind.public, local),
        AddressKind.public,
      );
      expect(
        effectiveAddressKind(AddressKind.local, public),
        AddressKind.public,
      );
    });

    test('a refused or unresolved verdict fails closed', () {
      final refused = verdict('http://example.com/c', '0.0.0.0');
      expect(effectiveAddressKind(AddressKind.public, refused), isNull);
      final unresolved = judgeAddress(Uri.parse('http://example.com/c'));
      expect(effectiveAddressKind(AddressKind.local, unresolved), isNull);
    });
  });

  test('policies carry the caps and who chose the address', () {
    expect(NetPolicy.repo.maxBytes, 1024 * 1024);
    expect(NetPolicy.package.maxBytes, 5 * 1024 * 1024);
    expect(NetPolicy.icon.maxBytes, 64 * 1024);
    expect(NetPolicy.link.maxBytes, NetPolicy.package.maxBytes);
    expect(NetPolicy.repo.fromCatalog, isFalse);
    expect(NetPolicy.link.fromCatalog, isFalse);
    expect(NetPolicy.package.fromCatalog, isTrue);
    expect(NetPolicy.icon.fromCatalog, isTrue);
  });
}
