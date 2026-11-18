import '../../../platform/domain/document_picker.dart';

/// The filter for picking an M3U file. [label] is shown by the dialog; the UI
/// passes its localized text. Extensions match in any case.
DocumentFilter m3uDocumentFilter({String label = 'M3U'}) => DocumentFilter(
  label: label,
  extensions: const ['m3u', 'm3u8'],
  mimeTypes: const [
    'audio/x-mpegurl',
    'audio/mpegurl',
    'application/vnd.apple.mpegurl',
  ],
);
