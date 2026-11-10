import 'package:flutter_test/flutter_test.dart';

import 'support/seed_guard.dart';

Map<String, String> _ok() => {
  'KANARU_SEED': '1',
  'XDG_CONFIG_HOME': '/tmp/kanaru-lane-b/config',
  'XDG_DATA_HOME': '/tmp/kanaru-lane-b/data',
  'XDG_CACHE_HOME': '/tmp/kanaru-lane-b/cache',
};

String same(String p) => p;

void main() {
  test('three roots under /tmp with the opt-in: allowed', () {
    expect(seedEnvironmentProblem(_ok(), resolve: same), isNull);
  });

  test('without KANARU_SEED=1 it refuses', () {
    final env = _ok()..remove('KANARU_SEED');
    expect(seedEnvironmentProblem(env, resolve: same), contains('KANARU_SEED=1'));
    env['KANARU_SEED'] = 'yes';
    expect(seedEnvironmentProblem(env, resolve: same), contains('KANARU_SEED=1'));
  });

  for (final name in ['XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME']) {
    test('$name unset, empty, relative or outside /tmp refuses', () {
      for (final bad in [null, '', 'relative/dir', '/home/user/.local/share']) {
        final env = _ok();
        if (bad == null) {
          env.remove(name);
        } else {
          env[name] = bad;
        }
        expect(
          seedEnvironmentProblem(env, resolve: same),
          contains(name),
          reason: '$name = $bad',
        );
      }
    });
  }

  test('.. cannot climb out of /tmp', () {
    final env = _ok()..['XDG_DATA_HOME'] = '/tmp/../home/user/.local/share';
    expect(seedEnvironmentProblem(env, resolve: same), contains('XDG_DATA_HOME'));
  });

  test('/tmp itself and a /tmp-prefixed sibling are refused', () {
    expect(
      seedEnvironmentProblem(_ok()..['XDG_DATA_HOME'] = '/tmp', resolve: same),
      contains('XDG_DATA_HOME'),
    );
    expect(
      seedEnvironmentProblem(
        _ok()..['XDG_DATA_HOME'] = '/tmpfoo/data',
        resolve: same,
      ),
      contains('XDG_DATA_HOME'),
    );
  });

  test('a link that leads out of /tmp is refused', () {
    final env = _ok();
    final problem = seedEnvironmentProblem(
      env,
      resolve: (p) => p.endsWith('/data') ? '/home/user/.local/share' : p,
    );
    expect(problem, contains('resolves to'));
  });
}
