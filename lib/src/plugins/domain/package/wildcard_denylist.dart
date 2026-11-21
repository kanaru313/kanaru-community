/// Bases a wildcard may not use: shared-hosting suffixes under which anyone
/// can register a name, so `*.<base>` would reach every tenant's site.
const deniedWildcardBases = {
  'workers.dev',
  'pages.dev',
  'github.io',
  'gitlab.io',
  'netlify.app',
  'vercel.app',
  'herokuapp.com',
  'appspot.com',
  'web.app',
  'firebaseapp.com',
  'cloudfront.net',
  'azurewebsites.net',
  'blogspot.com',
  'onrender.com',
  'fly.dev',
  'glitch.me',
  's3.amazonaws.com',
  'blob.core.windows.net',
  'ngrok.io',
  'ngrok-free.app',
  'trycloudflare.com',
  'googleusercontent.com',
};

/// Second-level registry labels of country domains (`co.uk`, `com.vn`): a
/// wildcard over `<registry>.<cc>` would reach every company of a country.
const _registryLabels = {
  'co', 'com', 'net', 'org', 'gov', 'edu', 'ac', 'or', 'ne', 'go', //
};
final _countryCode = RegExp(r'^[a-z]{2}$');

/// Whether [base] is a two-label country registry name such as `co.uk`.
bool _isCountryRegistry(String base) {
  final labels = base.split('.');
  return labels.length == 2 &&
      _registryLabels.contains(labels[0]) &&
      _countryCode.hasMatch(labels[1]);
}

/// Whether a wildcard over [base] is refused: a shared-hosting suffix (or a
/// name under one) or a country registry name.
bool wildcardBaseDenied(String base) =>
    _isCountryRegistry(base) ||
    deniedWildcardBases.any((d) => base == d || base.endsWith('.$d'));
