import '../../models/booking.dart';

/// Overlap detection for bookings on the same box.
///
/// Intervals are half-open: a booking 10:00-12:00 and another 12:00-14:00 do
/// **not** conflict (matches the original `from < b.end && to > b.start`).
class ConflictDetector {
  const ConflictDetector._();

  static bool overlaps(int startA, int endA, int startB, int endB) =>
      startA < endB && endA > startB;

  /// First existing booking that collides with the requested slot, or `null`.
  ///
  /// * cancelled bookings never block a slot
  /// * only bookings on the same [date] **and** [boxId] are considered
  /// * [excludeBookingId] skips the booking being edited
  /// * [excludeGroupId] skips the rows of a recurring group being regenerated
  static Booking? findConflict({
    required Iterable<Booking> existing,
    required String date,
    required String boxId,
    required int startMinutes,
    required int endMinutes,
    String? excludeBookingId,
    String? excludeGroupId,
  }) {
    for (final b in existing) {
      if (b.isCancelled) continue;
      if (b.date != date || b.boxId != boxId) continue;
      if (excludeBookingId != null && b.id == excludeBookingId) continue;
      if (excludeGroupId != null && b.recurringGroupId == excludeGroupId) {
        continue;
      }
      if (overlaps(startMinutes, endMinutes, b.startMinutes, b.endMinutes)) {
        return b;
      }
    }
    return null;
  }

  /// Dates (from [dates]) on which the requested slot is already taken.
  static List<String> conflictingDates({
    required Iterable<Booking> existing,
    required Iterable<String> dates,
    required String boxId,
    required int startMinutes,
    required int endMinutes,
    String? excludeGroupId,
  }) {
    final result = <String>[];
    for (final date in dates) {
      final hit = findConflict(
        existing: existing,
        date: date,
        boxId: boxId,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        excludeGroupId: excludeGroupId,
      );
      if (hit != null) result.add(date);
    }
    return result;
  }
}
