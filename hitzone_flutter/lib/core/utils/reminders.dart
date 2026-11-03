import '../../models/app_notification.dart';
import '../../models/booking.dart';
import 'formatters.dart';

class ReminderRules {
  const ReminderRules._();

  /// Bookings (confirmed / pending) that start within the next [withinMinutes].
  static List<Booking> dueSoon(
    Iterable<Booking> bookings,
    DateTime now, {
    int withinMinutes = 60,
  }) {
    final horizon = now.add(Duration(minutes: withinMinutes));
    return bookings.where((b) {
      if (b.status != BookingStatus.confirmed &&
          b.status != BookingStatus.pending) {
        return false;
      }
      final start = b.startsAt;
      return start.isAfter(now) && !start.isAfter(horizon);
    }).toList();
  }

  /// Deterministic id so a reminder is raised only once per booking.
  static String reminderId(Booking b) =>
      'reminder-${b.id}-${b.date}-${b.startTime}';

  static AppNotification build(Booking b, DateTime now) {
    final mins = b.startsAt.difference(now).inMinutes;
    return AppNotification(
      id: reminderId(b),
      title: 'Upcoming in ${mins <= 1 ? 'a minute' : '$mins min'}',
      message: '${b.name} · ${t12(b.startTime)} – ${t12(b.endTime)}',
      type: NotificationType.reminder,
      createdAt: now,
    );
  }
}
