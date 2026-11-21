import '../../../foundation/ids/stable_uid.dart';

const _prefix = 'plugin-';

/// The id of a plugin installed from a repository: `plugin-` plus 32 hex
/// characters (128 bits) of the hash of the source [repoUrl] and [slug].
///
/// [repoUrl] must be the canonical address from `canonicalRepoUrl`, so two
/// spellings of one repository give one id. The id is derived from where the
/// plugin came from, never from what the package says about itself, so a
/// package cannot claim another plugin's id.
String repoInstallId(String repoUrl, String slug) =>
    '$_prefix${stableHashHex(['repo', repoUrl, slug], 32)}';

/// The id of a plugin installed from a file or a link: `plugin-` plus 32 hex
/// characters of the hash of the manifest's [name] and [author] (null and ''
/// are the same). The two sources share it, so one plugin cannot be
/// installed twice by file and by link.
String fileInstallId(String name, String? author) =>
    '$_prefix${stableHashHex(['file', name, author ?? ''], 32)}';
