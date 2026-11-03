import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/booking_repository.dart';
import '../repositories/box_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/recurring_repository.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/customer_service.dart';
import '../services/export_service.dart';
import '../services/messaging_service.dart';
import '../services/realtime_service.dart';
import '../services/supabase_service.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseService.client,
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => SupabaseBookingRepository(ref.watch(supabaseClientProvider)),
);
final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => SupabaseCustomerRepository(ref.watch(supabaseClientProvider)),
);
final boxRepositoryProvider = Provider<BoxRepository>(
  (ref) => SupabaseBoxRepository(ref.watch(supabaseClientProvider)),
);
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => SupabaseExpenseRepository(ref.watch(supabaseClientProvider)),
);
final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => SupabaseRecurringRepository(ref.watch(supabaseClientProvider)),
);

final bookingServiceProvider = Provider<BookingService>(
  (ref) => BookingService(
    bookings: ref.watch(bookingRepositoryProvider),
    customers: ref.watch(customerRepositoryProvider),
    recurring: ref.watch(recurringRepositoryProvider),
  ),
);

final customerServiceProvider = Provider<CustomerService>(
  (ref) => CustomerService(
    customers: ref.watch(customerRepositoryProvider),
    bookings: ref.watch(bookingRepositoryProvider),
  ),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);
final messagingServiceProvider = Provider<MessagingService>(
  (ref) => MessagingService(),
);
final exportServiceProvider = Provider<ExportService>(
  (ref) => const ExportService(),
);
final realtimeServiceProvider = Provider<RealtimeService>(
  (ref) => RealtimeService(ref.watch(supabaseClientProvider)),
);
