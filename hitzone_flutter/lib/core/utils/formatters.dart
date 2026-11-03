import 'package:intl/intl.dart';

const List<String> kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Index matches `DateTime.weekday % 7` (Sunday = 0), the convention used by
/// the `recurring_groups.days` column.
const List<String> kDayNames = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

double toDouble(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int toInt(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

/// `HH:mm:ss` (Postgres `time`) or `HH:mm` -> `HH:mm`.
String normalizeTime(String? t) {
  if (t == null || t.isEmpty) return '';
  final parts = t.split(':');
  if (parts.length < 2) return t;
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}

/// `HH:mm` -> minutes since midnight. Returns 0 for malformed input.
int parseMinutes(String? t) {
  if (t == null || t.isEmpty) return 0;
  final parts = t.split(':');
  if (parts.length < 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

String minutesToTime(int minutes) {
  final m = minutes % (24 * 60);
  final h = m ~/ 60;
  return '${h.toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

/// `19:30` -> `7:30 PM`
String t12(String? t) {
  if (t == null || t.isEmpty) return '';
  final mins = parseMinutes(t);
  final h = mins ~/ 60;
  final m = mins % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
}

/// Duration in hours, rounded to one decimal (display value).
double calcHours(String? from, String? to) {
  if (from == null || to == null || from.isEmpty || to.isEmpty) return 0;
  final diff = parseMinutes(to) - parseMinutes(from);
  return (diff / 60 * 10).round() / 10;
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Today in the device's *local* time zone (the web app used UTC, which was
/// off by a day around midnight in India).
String todayKey([DateTime? now]) => dateKey(now ?? DateTime.now());

DateTime parseDateKey(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// `2026-11-03` -> `3 Nov 2026`
String fmtDate(String? s) {
  if (s == null || s.isEmpty) return '';
  try {
    return DateFormat('d MMM yyyy').format(parseDateKey(s));
  } catch (_) {
    return s;
  }
}

String fmtDateLong(DateTime d) => DateFormat('EEEE, d MMMM yyyy').format(d);

final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');

/// `1234567.5` -> `₹12,34,568`
String inr(num value) => '₹${_inr.format(value.round())}';

String initials(String? name) {
  final parts = (name ?? '?')
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty);
  if (parts.isEmpty) return '?';
  return parts.map((e) => e[0]).take(2).join().toUpperCase();
}

/// Strips everything but digits, drops a leading country code from 12 digit
/// numbers and keeps at most 10 digits.
String cleanPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    digits = digits.substring(2);
  }
  return digits.length > 10 ? digits.substring(0, 10) : digits;
}

bool isValidPhone(String phone) => RegExp(r'^\d{10}$').hasMatch(phone);

/// Naive relative time for notification timestamps.
String timeAgo(DateTime then, [DateTime? now]) {
  final diff = (now ?? DateTime.now()).difference(then);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) return 'Yesterday';
  return DateFormat('d MMM').format(then);
}
