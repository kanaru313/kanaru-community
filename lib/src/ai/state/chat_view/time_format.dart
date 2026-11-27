/// "14:32" in the device's time zone. Never a weekday, never a date.
String chatClock(DateTime at) {
  final t = at.toLocal();
  return '${_two(t.hour)}:${_two(t.minute)}';
}

/// "14:32 · 14/11/2026", what the footer time shows when it is opened.
String chatClockWithDate(DateTime at) {
  final t = at.toLocal();
  return '${chatClock(t)} · ${_two(t.day)}/${_two(t.month)}/${t.year}';
}

String _two(int n) => n.toString().padLeft(2, '0');
