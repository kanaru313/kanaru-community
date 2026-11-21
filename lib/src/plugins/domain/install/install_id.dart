import '../../../foundation/ids/stable_uid.dart';

const _prefix = 'plugin-';

/// The id of a plugin installed from a repository: `plugin-` plus 32 hex
/// characters (128 bits) of the hash of the source [repoUrl] and [slug].
///
/// [repoUrl] must be the canonical address from `canonicalRepoUrl`, so two
/// spellings of one repository give one id. The id is derived from where the
/// plugin came from, not from what the package says about itself.
String repoInstallId(String repoUrl, String slug) =>
    '$_prefix${stableHashHex(['repo', repoUrl, slug], 32)}';

/// The id of a plugin installed from a file or a link: `plugin-` plus 32 hex
/// characters of the hash of the manifest's [name] and [author] (null and ''
/// are the same). The two sources share it, so one plugin cannot be
/// installed twice by file and by link. The package chooses these two
/// values, so this id is not a trust boundary: an update is accepted only
/// from the install source of the installed plugin.
String fileInstallId(String name, String? author) =>
    '$_prefix${stableHashHex(['file', name, author ?? ''], 32)}';
