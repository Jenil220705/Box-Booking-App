import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/customer.dart';
import '../models/recurring_group.dart';
import '../screens/bookings/booking_form_screen.dart';
import '../screens/customers/customer_form_screen.dart';
import '../screens/recurring/recurring_form_screen.dart';
import '../screens/settings/boxes_screen.dart';

/// Full-screen routes (forms). Top-level pages live in the shell and are
/// switched through `currentPageProvider`.
class Routes {
  const Routes._();

  /// Opens the booking form. Returns true when something was saved.
  static Future<bool?> bookingForm(
    BuildContext context, {
    Booking? edit,
    String? date,
    String? from,
    String? boxId,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(
          edit: edit,
          prefillDate: date,
          prefillFrom: from,
          prefillBoxId: boxId,
        ),
      ),
    );
  }

  static Future<bool?> recurringForm(
    BuildContext context, {
    RecurringGroup? edit,
    String? date,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecurringFormScreen(edit: edit, prefillDate: date),
      ),
    );
  }

  static Future<bool?> customerForm(BuildContext context, {Customer? edit}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(edit: edit)),
    );
  }

  static Future<void> boxes(BuildContext context) {
    return Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const BoxesScreen()));
  }
}
