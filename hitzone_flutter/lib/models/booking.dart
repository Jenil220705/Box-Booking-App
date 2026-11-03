import '../core/utils/formatters.dart';

enum BookingStatus {
  confirmed,
  pending,
  completed,
  cancelled;

  static BookingStatus parse(String? value) {
    return BookingStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => BookingStatus.confirmed,
    );
  }

  String get label => name[0].toUpperCase() + name.substring(1);
}

/// A row of the Supabase `bookings` table.
class Booking {
  const Booking({
    required this.id,
    required this.name,
    required this.phone,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.amount,
    required this.boxId,
    this.ratePerHour,
    this.recurringGroupId,
  });

  final String id;
  final String name;
  final String phone;

  /// `yyyy-MM-dd`
  final String date;

  /// `HH:mm`
  final String startTime;
  final String endTime;
  final BookingStatus status;
  final double amount;
  final String boxId;
  final double? ratePerHour;
  final String? recurringGroupId;

  factory Booking.fromMap(Map<String, dynamic> m) {
    return Booking(
      id: m['id'].toString(),
      name: (m['customer_name'] ?? '') as String,
      phone: (m['phone'] ?? '').toString(),
      date: (m['booking_date'] ?? '').toString(),
      startTime: normalizeTime(m['start_time']?.toString()),
      endTime: normalizeTime(m['end_time']?.toString()),
      status: BookingStatus.parse(m['status']?.toString()),
      amount: toDouble(m['amount']),
      boxId: (m['box_id'] ?? '').toString(),
      ratePerHour: m['rate_per_hour'] == null
          ? null
          : toDouble(m['rate_per_hour']),
      recurringGroupId: m['recurring_group_id']?.toString(),
    );
  }

  int get startMinutes => parseMinutes(startTime);
  int get endMinutes => parseMinutes(endTime);
  double get hours => calcHours(startTime, endTime);
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isRecurring => recurringGroupId != null;

  /// Stored rate, or the rate implied by amount / duration for old rows.
  double get effectiveRate {
    if (ratePerHour != null) return ratePerHour!;
    final h = (endMinutes - startMinutes) / 60;
    return h > 0 ? amount / h : 0;
  }

  /// When the booking ends, in local time.
  DateTime get endsAt {
    final d = parseDateKey(date);
    return DateTime(d.year, d.month, d.day).add(Duration(minutes: endMinutes));
  }

  DateTime get startsAt {
    final d = parseDateKey(date);
    return DateTime(
      d.year,
      d.month,
      d.day,
    ).add(Duration(minutes: startMinutes));
  }

  Booking copyWith({
    String? name,
    String? phone,
    String? date,
    String? startTime,
    String? endTime,
    BookingStatus? status,
    double? amount,
    String? boxId,
    double? ratePerHour,
  }) {
    return Booking(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      boxId: boxId ?? this.boxId,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      recurringGroupId: recurringGroupId,
    );
  }
}

/// Values needed to create or fully update a booking.
class BookingDraft {
  const BookingDraft({
    required this.name,
    required this.phone,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.boxId,
    required this.ratePerHour,
    this.status = BookingStatus.confirmed,
    this.recurringGroupId,
  });

  final String name;
  final String phone;
  final String date;
  final String startTime;
  final String endTime;
  final String boxId;
  final double ratePerHour;
  final BookingStatus status;
  final String? recurringGroupId;

  int get startMinutes => parseMinutes(startTime);
  int get endMinutes => parseMinutes(endTime);

  /// hours x rate (exact duration, so 7:15-8:45 is billed as 1.5h).
  double get amount => bookingAmount(startTime, endTime, ratePerHour);

  Map<String, dynamic> toMap() => {
    'customer_name': name,
    'phone': phone,
    'booking_date': date,
    'start_time': startTime,
    'end_time': endTime,
    'amount': amount,
    'rate_per_hour': ratePerHour,
    'status': status.name,
    'box_id': boxId,
    if (recurringGroupId != null) 'recurring_group_id': recurringGroupId,
  };
}

double bookingAmount(String startTime, String endTime, double rate) {
  final minutes = parseMinutes(endTime) - parseMinutes(startTime);
  if (minutes <= 0) return 0;
  return (minutes / 60 * rate * 100).round() / 100;
}
