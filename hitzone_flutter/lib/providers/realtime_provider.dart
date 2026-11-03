import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';
import 'data_providers.dart';

/// Keeps bookings / recurring groups / customers in sync with the database.
/// Watch it once from the signed-in shell; it stops with the shell.
final realtimeProvider = Provider<void>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  Timer? bookingsTimer;
  Timer? recurringTimer;

  // Debounce: inserting a recurring group fires one event per row.
  void bookingsChanged() {
    bookingsTimer?.cancel();
    bookingsTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(bookingsProvider.notifier).refresh(silent: true);
      ref.read(customersProvider.notifier).refresh(silent: true);
    });
  }

  void recurringChanged() {
    recurringTimer?.cancel();
    recurringTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(recurringProvider.notifier).refresh(silent: true);
    });
  }

  service.start(
    onBookingsChanged: bookingsChanged,
    onRecurringChanged: recurringChanged,
    onStatus: (s) => debugPrint('Realtime status: $s'),
  );

  ref.onDispose(() {
    bookingsTimer?.cancel();
    recurringTimer?.cancel();
    service.stop();
  });
});
