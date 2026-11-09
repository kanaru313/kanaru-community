/// SQL condition: a live exclusion of the source [sourceId] covers [locator].
/// Both are SQL expressions (a column or a `?` placeholder); every use of an
/// expression is a separate occurrence, so a placeholder needs one variable
/// per occurrence, in this order: source id, locator, locator.
///
/// A folder covers `locator >= 'key/' AND locator < 'key0'`
/// (see `folderLocatorRange`); the empty key (root) covers everything. Works
/// for path-based sources only; an id-based source needs its own matching.
String liveExclusionCovers(String sourceId, String locator) =>
    'EXISTS (SELECT 1 FROM excluded_folders e WHERE e.source_id = $sourceId '
    'AND e.deleted_at IS NULL AND (e.folder_key = \'\' OR '
    "($locator >= e.folder_key || '/' AND $locator < e.folder_key || '0')))";
