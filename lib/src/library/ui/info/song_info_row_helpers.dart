import 'song_info_spec.dart';

String? infoText(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

InfoRowSpec textRow(InfoRowId id, String label, String? value, {String? copy}) {
  final v = infoText(value);
  return InfoRowSpec(id, label, value: v, copyText: copy, empty: v == null);
}

InfoRowSpec linksRow(
  InfoRowId id,
  String label,
  List<InfoLink> links, {
  String? badge,
}) => InfoRowSpec(
  id,
  label,
  kind: InfoRowKind.links,
  links: links,
  badge: links.isEmpty ? null : badge,
  empty: links.isEmpty,
);
