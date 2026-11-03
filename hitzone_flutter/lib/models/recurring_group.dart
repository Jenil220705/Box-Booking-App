import '../core/utils/formatters.dart';

/// A row of the Supabase `recurring_groups` table (joined with `boxes(name)`).
class RecurringGroup {
  const RecurringGroup({
    required this.id,
    required this.name,
    required this.phone,
    required this.boxId,
    required this.boxName,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.weeks,
    required this.ratePerHour,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String boxId;
  final String boxName;

  /// 0 = Sunday ... 6 = Saturday
  final List<int> days;
  final String startTime;
  final String endTime;
  final int weeks;
  final double ratePerHour;
  final DateTime? createdAt;

  factory RecurringGroup.fromMap(Map<String, dynamic> m) {
    final box = m['boxes'];
    return RecurringGroup(
      id: m['id'].toString(),
      name: (m['customer_name'] ?? '') as String,
      phone: (m['phone'] ?? '').toString(),
      boxId: (m['box_id'] ?? '').toString(),
      boxName: box is Map ? (box['name'] ?? '-').toString() : '-',
      days: ((m['days'] as List?) ?? const []).map((e) => toInt(e)).toList(),
      startTime: normalizeTime(m['start_time']?.toString()),
      endTime: normalizeTime(m['end_time']?.toString()),
      weeks: toInt(m['weeks']),
      ratePerHour: toDouble(m['rate_per_hour']),
      createdAt: m['created_at'] == null
          ? null
          : DateTime.tryParse(m['created_at'].toString())?.toLocal(),
    );
  }

  List<String> get dayLabels => days.map((d) => kDayNames[d % 7]).toList();

  /// Number of booking rows the group generates (`days x weeks`).
  int get bookingCount => days.length * weeks;
}

class RecurringDraft {
  const RecurringDraft({
    required this.name,
    required this.phone,
    required this.boxId,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.weeks,
    required this.ratePerHour,
    required this.startDate,
  });

  final String name;
  final String phone;
  final String boxId;
  final List<int> days;
  final String startTime;
  final String endTime;
  final int weeks;
  final double ratePerHour;

  /// First date from which the weekly pattern is generated (`yyyy-MM-dd`).
  final String startDate;

  /// Columns of the `recurring_groups` row.
  Map<String, dynamic> toGroupMap() => {
    'customer_name': name,
    'phone': phone,
    'box_id': boxId,
    'days': days,
    'start_time': startTime,
    'end_time': endTime,
    'weeks': weeks,
    'rate_per_hour': ratePerHour,
  };
}
