import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/app/theme.dart';
import 'package:hitzone_flutter/core/utils/formatters.dart';
import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/models/box.dart';
import 'package:hitzone_flutter/models/customer.dart';
import 'package:hitzone_flutter/models/expense.dart';
import 'package:hitzone_flutter/models/recurring_group.dart';
import 'package:hitzone_flutter/providers/core_providers.dart';
import 'package:hitzone_flutter/providers/data_providers.dart';
import 'package:hitzone_flutter/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeBookings extends BookingsNotifier {
  FakeBookings(this.items);
  final List<Booking> items;
  @override
  Future<List<Booking>> load() async => items;
}

class FakeCustomers extends CustomersNotifier {
  FakeCustomers(this.items);
  final List<Customer> items;
  @override
  Future<List<Customer>> load() async => items;
}

class FakeBoxes extends BoxesNotifier {
  FakeBoxes(this.items);
  final List<CricketBox> items;
  @override
  Future<List<CricketBox>> load() async => items;
}

class FakeExpenses extends ExpensesNotifier {
  FakeExpenses(this.items);
  final List<Expense> items;
  @override
  Future<List<Expense>> load() async => items;
}

class FakeRecurring extends RecurringNotifier {
  FakeRecurring(this.items);
  final List<RecurringGroup> items;
  @override
  Future<List<RecurringGroup>> load() async => items;
}

class FakeAuthService implements AuthService {
  @override
  Session? get currentSession => null;
  @override
  User? get currentUser => null;
  @override
  Stream<Session?> sessionChanges() => const Stream.empty();
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> updatePassword(String newPassword) async {}
}

Booking sampleBooking(
  String id, {
  String name = 'Rahul Shah',
  String phone = '9876543210',
  String? date,
  String start = '10:00',
  String end = '12:00',
  String box = '1',
  BookingStatus status = BookingStatus.confirmed,
  double amount = 3000,
}) => Booking(
  id: id,
  name: name,
  phone: phone,
  date: date ?? todayKey(),
  startTime: start,
  endTime: end,
  status: status,
  amount: amount,
  boxId: box,
  ratePerHour: 1500,
);

const sampleBoxes = [
  CricketBox(id: '1', name: 'Box A', active: true),
  CricketBox(id: '2', name: 'Box B', active: true),
];

/// Pumps [child] inside a themed Material app with every data provider
/// replaced by in-memory data (no Supabase needed).
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget child, {
  List<Booking> bookings = const [],
  List<Customer> customers = const [],
  List<CricketBox> boxes = sampleBoxes,
  List<Expense> expenses = const [],
  List<RecurringGroup> recurring = const [],
  Map<String, Object> prefs = const {},
  Size size = const Size(411, 891),
  Brightness brightness = Brightness.light,
  List<Override> extraOverrides = const [],
}) async {
  AppTheme.useGoogleFonts = false;
  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  final app = ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      authServiceProvider.overrideWithValue(FakeAuthService()),
      bookingsProvider.overrideWith(() => FakeBookings(bookings)),
      customersProvider.overrideWith(() => FakeCustomers(customers)),
      boxesProvider.overrideWith(() => FakeBoxes(boxes)),
      expensesProvider.overrideWith(() => FakeExpenses(expenses)),
      recurringProvider.overrideWith(() => FakeRecurring(recurring)),
      ...extraOverrides,
    ],
    child: MaterialApp(
      theme: AppTheme.build(brightness),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
}
