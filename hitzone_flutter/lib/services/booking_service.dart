import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/utils/conflict_detector.dart';
import '../core/utils/errors.dart';
import '../core/utils/formatters.dart';
import '../core/utils/recurring_generator.dart';
import '../models/booking.dart';
import '../models/recurring_group.dart';
import '../repositories/booking_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/recurring_repository.dart';

class BookingOutcome {
  const BookingOutcome(this.booking, {this.newCustomer = false});
  final Booking booking;
  final bool newCustomer;
}

class RecurringOutcome {
  const RecurringOutcome(this.group, this.bookings, {this.newCustomer = false});
  final RecurringGroup group;
  final List<Booking> bookings;
  final bool newCustomer;
}

/// Business rules for bookings: validation, conflict detection, customer
/// counters and recurring-group generation. UI-agnostic and repository-backed
/// so it can be unit tested with in-memory fakes.
class BookingService {
  BookingService({
    required this._bookings,
    required this._customers,
    required this._recurring,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final BookingRepository _bookings;
  final CustomerRepository _customers;
  final RecurringRepository _recurring;
  final DateTime Function() _clock;

  // ---------------------------------------------------------------- validation

  static void validateDraft(BookingDraft d) {
    if (d.name.trim().isEmpty ||
        d.phone.isEmpty ||
        d.date.isEmpty ||
        d.startTime.isEmpty ||
        d.endTime.isEmpty ||
        d.boxId.isEmpty) {
      throw const ValidationException('Fill all required fields');
    }
    if (!isValidPhone(d.phone)) {
      throw const ValidationException('Enter valid 10 digit mobile number');
    }
    if (d.endMinutes <= d.startMinutes) {
      throw const ValidationException('End time must be after start time');
    }
    if (d.ratePerHour < 0) {
      throw const ValidationException('Rate cannot be negative');
    }
  }

  static void validateRecurring(RecurringDraft d) {
    if (d.name.trim().isEmpty ||
        d.boxId.isEmpty ||
        d.startDate.isEmpty ||
        d.startTime.isEmpty ||
        d.endTime.isEmpty) {
      throw const ValidationException('Fill required fields');
    }
    if (!isValidPhone(d.phone)) {
      throw const ValidationException('Enter valid 10 digit mobile number');
    }
    if (d.ratePerHour <= 0) {
      throw const ValidationException('Enter the hourly rate');
    }
    if (d.days.isEmpty) {
      throw const ValidationException('Select at least one day');
    }
    if (d.weeks < 1 || d.weeks > 52) {
      throw const ValidationException('Weeks must be between 1 and 52');
    }
    if (parseMinutes(d.endTime) <= parseMinutes(d.startTime)) {
      throw const ValidationException('End time must be after start time');
    }
  }

  // ------------------------------------------------------------ single booking

  Future<BookingOutcome> createBooking(
    BookingDraft draft, {
    bool detectConflicts = true,
  }) async {
    validateDraft(draft);
    if (detectConflicts) await _assertSlotFree(draft);
    final created = await _bookings.insert(draft);
    final isNew = await _recordCustomerBookings(draft.name, draft.phone, 1);
    return BookingOutcome(created, newCustomer: isNew);
  }

  Future<BookingOutcome> updateBooking(
    Booking original,
    BookingDraft draft, {
    bool detectConflicts = true,
  }) async {
    validateDraft(draft);
    if (detectConflicts) {
      await _assertSlotFree(draft, excludeBookingId: original.id);
    }
    final updated = await _bookings.update(original.id, draft);
    var isNew = false;
    if (original.phone != draft.phone) {
      await _removeCustomerBookings(original.phone, 1);
      isNew = await _recordCustomerBookings(draft.name, draft.phone, 1);
    }
    return BookingOutcome(updated, newCustomer: isNew);
  }

  Future<void> changeStatus(Booking booking, BookingStatus status) =>
      _bookings.updateStatus(booking.id, status);

  Future<void> deleteBooking(Booking booking) async {
    await _bookings.delete(booking.id);
    await _removeCustomerBookings(booking.phone, 1);
  }

  /// Removes the last hour of a booking (minimum duration stays 1 hour) and
  /// re-prices it at the booking's own hourly rate.
  Future<Booking> reduceOneHour(Booking booking) async {
    if (booking.endMinutes - booking.startMinutes <= 60) {
      throw const ValidationException('Minimum 1 hour — cannot reduce further');
    }
    final newEnd = minutesToTime(booking.endMinutes - 60);
    final amount = bookingAmount(
      booking.startTime,
      newEnd,
      booking.effectiveRate,
    );
    await _bookings.updateEndTime(booking.id, newEnd, amount);
    return booking.copyWith(endTime: newEnd, amount: amount);
  }

  Future<void> _assertSlotFree(
    BookingDraft draft, {
    String? excludeBookingId,
  }) async {
    final existing = await _bookings.fetchForBoxOnDates(draft.boxId, [
      draft.date,
    ]);
    final clash = ConflictDetector.findConflict(
      existing: existing,
      date: draft.date,
      boxId: draft.boxId,
      startMinutes: draft.startMinutes,
      endMinutes: draft.endMinutes,
      excludeBookingId: excludeBookingId,
    );
    if (clash != null) {
      throw SlotConflictException(
        'Slot already booked (${clash.name}, ${t12(clash.startTime)} – ${t12(clash.endTime)})',
        dates: [draft.date],
      );
    }
  }

  // ----------------------------------------------------------------- recurring

  Future<RecurringOutcome> createRecurring(
    RecurringDraft draft, {
    bool detectConflicts = true,
  }) async {
    validateRecurring(draft);
    final dates = RecurringGenerator.generate(
      startDate: draft.startDate,
      days: draft.days,
      weeks: draft.weeks,
    );
    if (detectConflicts) await _assertRecurringFree(draft, dates);

    final group = await _recurring.insert(draft);
    final List<Booking> created;
    try {
      created = await _bookings.insertMany(_draftsFor(draft, dates, group.id));
    } catch (_) {
      // Don't leave an empty group behind if the bookings were rejected.
      try {
        await _recurring.delete(group.id);
      } catch (e) {
        debugPrint('Could not roll back recurring group ${group.id}: $e');
      }
      rethrow;
    }
    final isNew = await _recordCustomerBookings(
      draft.name,
      draft.phone,
      created.length,
    );
    return RecurringOutcome(group, created, newCustomer: isNew);
  }

  /// Regenerates a group: conflicts are checked first (ignoring the group's own
  /// bookings), then the group is updated and its bookings recreated.
  Future<RecurringOutcome> updateRecurring(
    RecurringGroup group,
    RecurringDraft draft, {
    bool detectConflicts = true,
  }) async {
    validateRecurring(draft);
    final dates = RecurringGenerator.generate(
      startDate: draft.startDate,
      days: draft.days,
      weeks: draft.weeks,
    );
    if (detectConflicts) {
      await _assertRecurringFree(draft, dates, excludeGroupId: group.id);
    }

    await _recurring.update(group.id, draft);
    await _bookings.deleteByGroup(group.id);
    final created = await _bookings.insertMany(
      _draftsFor(draft, dates, group.id),
    );
    final updated = RecurringGroup(
      id: group.id,
      name: draft.name,
      phone: draft.phone,
      boxId: draft.boxId,
      boxName: group.boxName,
      days: draft.days,
      startTime: draft.startTime,
      endTime: draft.endTime,
      weeks: draft.weeks,
      ratePerHour: draft.ratePerHour,
      createdAt: group.createdAt,
    );
    return RecurringOutcome(updated, created);
  }

  Future<void> deleteRecurring(RecurringGroup group) async {
    await _bookings.deleteByGroup(group.id);
    await _recurring.delete(group.id);
  }

  Future<void> _assertRecurringFree(
    RecurringDraft draft,
    List<String> dates, {
    String? excludeGroupId,
  }) async {
    final existing = await _bookings.fetchForBoxOnDates(draft.boxId, dates);
    final clashes = ConflictDetector.conflictingDates(
      existing: existing,
      dates: dates,
      boxId: draft.boxId,
      startMinutes: parseMinutes(draft.startTime),
      endMinutes: parseMinutes(draft.endTime),
      excludeGroupId: excludeGroupId,
    );
    if (clashes.isNotEmpty) {
      final shown = clashes.take(3).map(fmtDate).join(', ');
      final more = clashes.length > 3 ? ' +${clashes.length - 3} more' : '';
      throw SlotConflictException(
        'Already booked on $shown$more',
        dates: clashes,
      );
    }
  }

  List<BookingDraft> _draftsFor(
    RecurringDraft d,
    List<String> dates,
    String groupId,
  ) => [
    for (final date in dates)
      BookingDraft(
        name: d.name,
        phone: d.phone,
        date: date,
        startTime: d.startTime,
        endTime: d.endTime,
        boxId: d.boxId,
        ratePerHour: d.ratePerHour,
        recurringGroupId: groupId,
      ),
  ];

  // ------------------------------------------------------------------ customers

  /// Bumps the customer's lifetime counter, creating the customer when the
  /// phone number is new. Returns true when a customer was created. Failures
  /// are logged only: the booking itself is already saved.
  Future<bool> _recordCustomerBookings(
    String name,
    String phone,
    int count,
  ) async {
    try {
      final last = fmtDate(todayKey(_clock()));
      final existing = await _customers.findByPhone(phone);
      if (existing != null) {
        await _customers.updateCounter(
          existing.id,
          cnt: existing.cnt + count,
          last: last,
        );
        return false;
      }
      await _customers.insert(name: name, phone: phone, cnt: count, last: last);
      return true;
    } catch (e) {
      debugPrint('Customer counter update failed: $e');
      return false;
    }
  }

  Future<void> _removeCustomerBookings(String phone, int count) async {
    try {
      final existing = await _customers.findByPhone(phone);
      if (existing == null) return;
      await _customers.updateCounter(
        existing.id,
        cnt: math.max(0, existing.cnt - count),
      );
    } catch (e) {
      debugPrint('Customer counter update failed: $e');
    }
  }
}
