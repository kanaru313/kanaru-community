import 'package:flutter/services.dart';

import '../../foundation/result.dart';
import '../domain/document_picker.dart';
import 'media_store/media_store_channel_client.dart';

const _externalStorageAuthority = 'com.android.externalstorage.documents';
const _downloadsAuthority = 'com.android.providers.downloads.documents';

/// Filesystem path of a SAF document, or null when the provider does not
/// expose one (`msf:`, `home:`, media, cloud, unknown authorities).
///
/// - external storage: `primary:Music/x.m3u8` -> `<primaryRoot>/Music/x.m3u8`,
///   `ABCD-1234:x` -> `/storage/ABCD-1234/x`; split on the first `:`.
/// - downloads: `raw:/storage/...` -> that path.
String? documentPathOf(
  String authority,
  String documentId,
  String primaryRoot,
) {
  final colon = documentId.indexOf(':');
  if (colon <= 0) return null;
  final volume = documentId.substring(0, colon);
  final rest = documentId.substring(colon + 1);
  final String? path;
  switch (authority) {
    case _externalStorageAuthority:
      if (volume == 'home') {
        path = null;
      } else if (volume == 'primary') {
        path = rest.replaceAll(RegExp('^/+'), '').isEmpty
            ? primaryRoot
            : '$primaryRoot/${rest.replaceAll(RegExp('^/+'), '')}';
      } else {
        path = rest.isEmpty ? '/storage/$volume' : '/storage/$volume/$rest';
      }
    case _downloadsAuthority:
      path = volume == 'raw' && rest.startsWith('/') ? rest : null;
    default:
      path = null;
  }
  if (path == null || path.split('/').contains('..')) return null;
  return path;
}

/// Android picker over the `kanaru/documents` channel (SAF: one document at
/// a time, no storage permission, no persisted grant).
class AndroidDocumentPicker implements DocumentPicker {
  AndroidDocumentPicker({
    MethodChannel? channel,
    Future<String> Function()? primaryRoot,
  }) : _channel = channel ?? const MethodChannel(channelName),
       _primaryRoot = primaryRoot ?? MediaStoreChannelClient().primaryRoot;

  static const channelName = 'kanaru/documents';

  final MethodChannel _channel;
  final Future<String> Function() _primaryRoot;

  @override
  Future<PickedDocument?> openDocument(DocumentFilter filter) async {
    final map = await _pick('open', {'mimeTypes': _mimeTypesFor(filter)});
    if (map == null) return null;
    final uri = map['uri'] as String;
    final name = (map['name'] as String?) ?? uri;
    return PickedDocument(
      name: name,
      handle: uri,
      localPath: await _pathOf(map),
    );
  }

  /// The MIME types offered for [filter]. Providers often report a file as
  /// `application/octet-stream`, so that one is always added. Playlist and
  /// plain-text types are added only for a playlist filter (it lists `m3u` /
  /// `m3u8`): offering them to every dialog would show `.m3u` and `.txt`
  /// files in, say, the font picker. The caller checks the name anyway.
  static List<String> _mimeTypesFor(DocumentFilter filter) {
    final isPlaylist = filter.extensions
        .map((e) => e.toLowerCase())
        .any((e) => e == 'm3u' || e == 'm3u8');
    // A set keeps the order and drops a type the filter already lists.
    return {
      ...filter.mimeTypes,
      if (isPlaylist) ...[
        'audio/x-mpegurl',
        'audio/mpegurl',
        'application/vnd.apple.mpegurl',
        'text/plain',
      ],
      'application/octet-stream',
    }.toList();
  }

  @override
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  }) async {
    final map = await _pick('create', {'name': suggestedName});
    if (map == null) return null;
    final uri = map['uri'] as String;
    return SaveTarget(
      name: (map['displayName'] as String?) ?? suggestedName,
      handle: uri,
      localPath: await _pathOf(map),
    );
  }

  @override
  Future<Result<Uint8List, DocumentError>> read(
    PickedDocument doc, {
    required int maxBytes,
  }) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('read', {
        'uri': doc.handle,
        'max': maxBytes,
      });
      if (bytes == null) return const Err(DocumentError.unreadable);
      if (bytes.length > maxBytes) return const Err(DocumentError.tooLarge);
      return Ok(bytes);
    } on PlatformException catch (e) {
      return Err(switch (e.code) {
        'too_large' => DocumentError.tooLarge,
        'not_found' => DocumentError.notAFile,
        _ => DocumentError.unreadable,
      });
    } on MissingPluginException {
      return const Err(DocumentError.unsupported);
    }
  }

  @override
  Future<Result<void, DocumentError>> write(
    SaveTarget target,
    Uint8List bytes,
  ) async {
    try {
      await _channel.invokeMethod<void>('write', {
        'uri': target.handle,
        'bytes': bytes,
      });
      return const Ok(null);
    } on PlatformException {
      return const Err(DocumentError.unwritable);
    } on MissingPluginException {
      return const Err(DocumentError.unsupported);
    }
  }

  @override
  Future<void> discard(SaveTarget target) async {
    try {
      await _channel.invokeMethod<void>('discard', {'uri': target.handle});
    } on PlatformException {
      // Best effort: an empty leftover document is harmless.
    } on MissingPluginException {
      // No native side.
    }
  }

  /// One dialog call. Null = cancelled (also when the activity went away).
  /// A second dialog while one is open throws [DocumentPickerException];
  /// the call never times out on this side (the user may take minutes). The
  /// native side answers null when the owning activity is gone for good or
  /// its result does not come back after a re-creation, so a later call works.
  Future<Map<Object?, Object?>?> _pick(
    String method,
    Map<String, Object?> args,
  ) async {
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(method, args);
    } on PlatformException catch (e) {
      throw DocumentPickerException(switch (e.code) {
        'busy' => DocumentPickerFailure.busy,
        'unavailable' => DocumentPickerFailure.unavailable,
        _ => DocumentPickerFailure.failed,
      }, e.message);
    } on MissingPluginException catch (e) {
      throw DocumentPickerException(
        DocumentPickerFailure.unavailable,
        e.message,
      );
    }
  }

  Future<String?> _pathOf(Map<Object?, Object?> map) async {
    final authority = map['authority'] as String?;
    final id = map['documentId'] as String?;
    if (authority == null || id == null) return null;
    try {
      return documentPathOf(authority, id, await _primaryRoot());
    } on MediaStoreException {
      return null;
    }
  }
}
