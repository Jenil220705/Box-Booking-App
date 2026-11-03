import '../../models/booking.dart';
import 'formatters.dart';

/// Builds RFC 4180 CSV (fields containing commas, quotes or line breaks are
/// quoted – the web app joined with plain commas and broke on such names).
class CsvBuilder {
  const CsvBuilder._();

  static String escape(Object? value) {
    final s = value?.toString() ?? '';
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String fromRows(List<List<Object?>> rows) =>
      rows.map((r) => r.map(escape).join(',')).join('\r\n');

  static String bookings(
    Iterable<Booking> bookings, {
    String Function(String boxId)? boxName,
  }) {
    final rows = <List<Object?>>[
      [
        'Name',
        'Phone',
        'Date',
        'From',
        'To',
        'Hours',
        'Amount',
        'Status',
        if (boxName != null) 'Box',
      ],
      for (final b in bookings)
        [
          b.name,
          b.phone,
          b.date,
          b.startTime,
          b.endTime,
          calcHours(b.startTime, b.endTime),
          b.amount.toStringAsFixed(
            b.amount == b.amount.roundToDouble() ? 0 : 2,
          ),
          b.status.name,
          if (boxName != null) boxName(b.boxId),
        ],
    ];
    return fromRows(rows);
  }
}
