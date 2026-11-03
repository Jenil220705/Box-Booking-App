import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/app/theme.dart';
import 'package:hitzone_flutter/core/utils/formatters.dart';
import 'package:hitzone_flutter/core/utils/message_templates.dart';
import 'package:hitzone_flutter/models/app_notification.dart';
import 'package:hitzone_flutter/models/booking.dart';
import 'package:hitzone_flutter/models/customer.dart';
import 'package:hitzone_flutter/models/expense.dart';
import 'package:hitzone_flutter/models/recurring_group.dart';
import 'package:hitzone_flutter/providers/notifications_provider.dart';
import 'package:hitzone_flutter/providers/settings_provider.dart';
import 'package:hitzone_flutter/screens/auth/login_screen.dart';
import 'package:hitzone_flutter/screens/bookings/bookings_screen.dart';
import 'package:hitzone_flutter/screens/calendar/calendar_screen.dart';
import 'package:hitzone_flutter/screens/customers/customers_screen.dart';
import 'package:hitzone_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:hitzone_flutter/screens/expenses/expenses_screen.dart';
import 'package:hitzone_flutter/screens/notifications/notifications_screen.dart';
import 'package:hitzone_flutter/screens/recurring/recurring_screen.dart';
import 'package:hitzone_flutter/screens/reports/reports_screen.dart';
import 'package:hitzone_flutter/screens/settings/boxes_screen.dart';
import 'package:hitzone_flutter/screens/settings/settings_screen.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() => AppTheme.useGoogleFonts = false);

  group('login', () {
    testWidgets('shows validation errors for empty fields', (tester) async {
      await pumpScreen(tester, const LoginScreen());
      await tester.tap(find.text('Sign In to Admin Panel →'));
      await tester.pump();
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('rejects a malformed email', (tester) async {
      await pumpScreen(tester, const LoginScreen());
      await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
      await tester.enterText(find.byType(TextFormField).last, 'secret');
      await tester.tap(find.text('Sign In to Admin Panel →'));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('password can be revealed', (tester) async {
      await pumpScreen(tester, const LoginScreen());
      final field = find.byType(EditableText).last;
      expect(tester.widget<EditableText>(field).obscureText, isTrue);
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();
      expect(tester.widget<EditableText>(field).obscureText, isFalse);
    });
  });

  group('bookings list', () {
    final data = [
      sampleBooking('1', name: 'Rahul Shah', phone: '9876543210'),
      sampleBooking(
        '2',
        name: 'Amit Patel',
        phone: '8765432109',
        start: '14:00',
        end: '16:00',
        status: BookingStatus.pending,
      ),
      sampleBooking(
        '3',
        name: 'Priya Shah',
        phone: '7654321098',
        date: '2020-01-01',
        status: BookingStatus.completed,
      ),
      sampleBooking(
        '4',
        name: 'Cancelled Carl',
        phone: '6543210987',
        status: BookingStatus.cancelled,
        amount: 0,
      ),
    ];

    testWidgets('lists bookings with their details', (tester) async {
      await pumpScreen(tester, const BookingsScreen(), bookings: data);
      expect(find.text('4 bookings'), findsOneWidget);
      expect(find.text('Rahul Shah'), findsOneWidget);
      expect(find.text('Amit Patel'), findsOneWidget);
      expect(find.text('₹3,000'), findsWidgets);
    });

    testWidgets('search filters by name and phone', (tester) async {
      await pumpScreen(tester, const BookingsScreen(), bookings: data);
      await tester.enterText(find.byType(TextField).first, 'shah');
      await tester.pump();
      expect(find.text('2 bookings'), findsOneWidget);
      expect(find.text('Amit Patel'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '8765432109');
      await tester.pump();
      expect(find.text('1 booking'), findsOneWidget);
      expect(find.text('Amit Patel'), findsOneWidget);
    });

    testWidgets('status chips filter the list', (tester) async {
      await pumpScreen(tester, const BookingsScreen(), bookings: data);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
      await tester.pump();
      expect(find.text('1 booking'), findsOneWidget);
      expect(find.text('Amit Patel'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pump();
      expect(find.text('4 bookings'), findsOneWidget);
    });

    testWidgets('shows an empty state when nothing matches', (tester) async {
      await pumpScreen(tester, const BookingsScreen(), bookings: data);
      await tester.enterText(find.byType(TextField).first, 'zzzz');
      await tester.pump();
      expect(find.text('No bookings found'), findsOneWidget);
    });

    testWidgets('empty database offers to create the first booking', (
      tester,
    ) async {
      await pumpScreen(tester, const BookingsScreen());
      expect(find.text('No bookings yet'), findsOneWidget);
      expect(find.text('New Booking'), findsOneWidget);
    });

    testWidgets('tapping a card opens the detail sheet with status chips', (
      tester,
    ) async {
      await pumpScreen(tester, const BookingsScreen(), bookings: data);
      await tester.tap(find.text('Rahul Shah'));
      await tester.pumpAndSettle();
      expect(find.text('Change status'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Completed'), findsWidgets);
      expect(find.text('Delete'), findsWidgets);
    });
  });

  group('calendar', () {
    testWidgets('shows the current month and the selected day overview', (
      tester,
    ) async {
      final now = DateTime.now();
      await pumpScreen(
        tester,
        const CalendarScreen(),
        bookings: [sampleBooking('1', name: 'Today Guy')],
      );
      expect(
        find.text('${kMonthNames[now.month - 1]} ${now.year}'),
        findsOneWidget,
      );
      expect(find.text('Today Guy'), findsOneWidget);
      expect(find.text('New Booking'), findsOneWidget);
      expect(find.text('Recurring'), findsOneWidget);
    });

    testWidgets('month navigation changes the heading', (tester) async {
      final now = DateTime.now();
      await pumpScreen(tester, const CalendarScreen());
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      final next = DateTime(now.year, now.month + 1);
      expect(
        find.text('${kMonthNames[next.month - 1]} ${next.year}'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Today'));
      await tester.pump();
      expect(
        find.text('${kMonthNames[now.month - 1]} ${now.year}'),
        findsOneWidget,
      );
    });

    testWidgets('cancelled bookings are not shown', (tester) async {
      await pumpScreen(
        tester,
        const CalendarScreen(),
        bookings: [
          sampleBooking('1', name: 'Gone', status: BookingStatus.cancelled),
        ],
      );
      expect(find.text('Gone'), findsNothing);
      expect(find.text('0 bookings'), findsOneWidget);
    });
  });

  group('dashboard', () {
    testWidgets('computes stats from the data', (tester) async {
      await pumpScreen(
        tester,
        const DashboardScreen(),
        bookings: [
          sampleBooking('1', amount: 3000),
          sampleBooking(
            '2',
            name: 'Second',
            start: '14:00',
            end: '16:00',
            amount: 2000,
          ),
          sampleBooking(
            '3',
            name: 'Cancelled',
            status: BookingStatus.cancelled,
            amount: 9999,
          ),
        ],
        expenses: [
          Expense(
            id: '1',
            title: 'Bulbs',
            amount: 500,
            category: 'Electricity',
            note: '',
            expenseDate: todayKey(),
          ),
        ],
      );
      expect(find.textContaining('Admin'), findsWidgets);
      expect(find.text("Today's Bookings"), findsOneWidget);
      // 2 active bookings today; 3000 + 2000 revenue; 500 expense -> 4500 profit.
      expect(find.text('₹5,000'), findsWidgets);
      expect(find.text('₹500'), findsWidgets);
      expect(find.text('₹4,500'), findsWidgets);
      expect(find.text('Occupancy'), findsOneWidget);
    });
  });

  group('customers', () {
    testWidgets('lists customers with stats and filters by search', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const CustomersScreen(),
        customers: const [
          Customer(
            id: '1',
            name: 'Rahul Shah',
            phone: '9876543210',
            cnt: 12,
            last: '1 Nov 2026',
          ),
          Customer(id: '2', name: 'Amit Patel', phone: '8765432109', cnt: 3),
        ],
        bookings: [sampleBooking('1', phone: '9876543210')],
      );
      expect(find.text('Rahul Shah'), findsOneWidget);
      expect(find.text('Amit Patel'), findsOneWidget);
      expect(
        find.text('👑'),
        findsOneWidget,
        reason: 'VIP badge at 10+ bookings',
      );
      await tester.enterText(find.byType(TextField).first, 'amit');
      await tester.pump();
      expect(find.text('Rahul Shah'), findsNothing);
      expect(find.text('Amit Patel'), findsOneWidget);
    });
  });

  group('recurring', () {
    testWidgets('shows groups and the how-it-works banner', (tester) async {
      await pumpScreen(
        tester,
        const RecurringScreen(),
        recurring: const [
          RecurringGroup(
            id: 'g1',
            name: 'Kiran Dave',
            phone: '9123456780',
            boxId: '1',
            boxName: 'Box A',
            days: [0, 3],
            startTime: '19:00',
            endTime: '21:00',
            weeks: 4,
            ratePerHour: 1200,
          ),
        ],
      );
      expect(find.text('Kiran Dave'), findsOneWidget);
      expect(find.text('8 bookings'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
    });
  });

  group('expenses', () {
    testWidgets('validates the form before saving', (tester) async {
      await pumpScreen(tester, const ExpensesScreen());
      await tester.tap(find.text('Add Expense').last);
      await tester.pump();
      expect(find.text('Enter an expense name'), findsOneWidget);
      expect(find.text('Enter an amount'), findsOneWidget);
    });

    testWidgets('totals, list and category filter', (tester) async {
      await pumpScreen(
        tester,
        const ExpensesScreen(),
        expenses: [
          Expense(
            id: '1',
            title: 'Ground rent',
            amount: 1000,
            category: 'Ground',
            note: 'Nov',
            expenseDate: todayKey(),
          ),
          Expense(
            id: '2',
            title: 'Staff',
            amount: 2500,
            category: 'Salary',
            note: '',
            expenseDate: todayKey(),
          ),
        ],
      );
      expect(find.text('₹3,500'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Staff'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ground rent'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Expense List (2)'), findsOneWidget);
    });
  });

  group('reports', () {
    testWidgets('renders analytics from bookings and expenses', (tester) async {
      await pumpScreen(
        tester,
        const ReportsScreen(),
        bookings: [
          sampleBooking('1', amount: 3000),
          sampleBooking(
            '2',
            name: 'Amit Patel',
            phone: '8765432109',
            start: '14:00',
            end: '16:00',
            amount: 2000,
          ),
        ],
        expenses: [
          Expense(
            id: '1',
            title: 'x',
            amount: 1000,
            category: 'Water',
            note: '',
            expenseDate: todayKey(),
          ),
        ],
      );
      expect(find.text('Total Bookings'), findsOneWidget);
      expect(find.text('₹5,000'), findsWidgets);
      expect(find.text('₹4,000'), findsOneWidget, reason: 'net profit');
      await tester.scrollUntilVisible(
        find.text('Export CSV'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Top customers by revenue'), findsOneWidget);
    });

    testWidgets('custom period asks for both dates', (tester) async {
      await pumpScreen(
        tester,
        const ReportsScreen(),
        bookings: [sampleBooking('1')],
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Custom'));
      await tester.pump();
      expect(find.text('Pick both dates to see the report.'), findsOneWidget);
    });
  });

  group('notifications', () {
    testWidgets('empty state', (tester) async {
      await pumpScreen(tester, const NotificationsScreen());
      expect(find.textContaining('No notifications yet'), findsOneWidget);
    });

    testWidgets('tapping marks as read; mark-all clears the unread count', (
      tester,
    ) async {
      final container = await pumpScreen(tester, const NotificationsScreen());
      final n = container.read(notificationsProvider.notifier);
      n.add(
        'New Booking – Rahul',
        'Today 10 AM',
        NotificationType.booking,
        id: 'a',
      );
      n.add(
        '⚠️ Conflict Detected',
        'Overlap',
        NotificationType.conflict,
        id: 'b',
      );
      await tester.pump();
      expect(find.text('2 unread'), findsOneWidget);

      await tester.tap(find.text('New Booking – Rahul'));
      await tester.pump();
      expect(find.text('1 unread'), findsOneWidget);

      await tester.tap(find.text('Mark All Read'));
      await tester.pump();
      expect(find.text('0 unread'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('dark mode toggle persists to the settings provider', (
      tester,
    ) async {
      final container = await pumpScreen(tester, const SettingsScreen());
      expect(container.read(settingsProvider).darkMode, isFalse);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Dark Mode'));
      await tester.pump();
      expect(container.read(settingsProvider).darkMode, isTrue);
    });

    testWidgets('template editor inserts variables and saves', (tester) async {
      // Tall surface so every section is built without scrolling.
      final container = await pumpScreen(
        tester,
        const SettingsScreen(),
        size: const Size(411, 5000),
      );
      final smsCard = find.ancestor(
        of: find.text('📱 SMS Message Template'),
        matching: find.byType(Card),
      );
      final smsField = find.descendant(
        of: smsCard,
        matching: find.byType(TextField),
      );

      await tester.enterText(smsField, 'Hi ');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: smsCard,
          matching: find.widgetWithText(ActionChip, '{name}'),
        ),
      );
      await tester.pump();
      expect(tester.widget<TextField>(smsField).controller!.text, 'Hi {name}');

      await tester.tap(
        find.descendant(of: smsCard, matching: find.text('Save SMS Template')),
      );
      await tester.pump();
      expect(container.read(settingsProvider).smsTemplate, 'Hi {name}');

      // Reset restores the shipped default.
      await tester.tap(
        find.descendant(of: smsCard, matching: find.text('Reset')),
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(smsField).controller!.text,
        MessageTemplates.defaultSms,
      );
    });

    testWidgets('shows the active box count', (tester) async {
      await pumpScreen(tester, const SettingsScreen());
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Update Boxes'), findsOneWidget);
    });
  });

  testWidgets('box management lists boxes with switches', (tester) async {
    await pumpScreen(tester, const BoxesScreen());
    expect(find.text('Box A'), findsOneWidget);
    expect(find.text('Box B'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(2));
  });

  group('dark mode', () {
    testWidgets('screens render in the dark theme', (tester) async {
      await pumpScreen(
        tester,
        const DashboardScreen(),
        bookings: [sampleBooking('1')],
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
      expect(
        Theme.of(tester.element(find.byType(DashboardScreen))).brightness,
        Brightness.dark,
      );
    });

    test('design tokens differ between themes', () {
      expect(HzColors.dark.bg, isNot(HzColors.light.bg));
      expect(HzColors.light.blue, const Color(0xFF0EA5E9));
    });
  });

  group('responsive layouts', () {
    const sizes = {
      'small phone 320x568': Size(320, 568),
      'phone 360x800': Size(360, 800),
      'large phone 411x891': Size(411, 891),
      'tablet 800x1280': Size(800, 1280),
    };

    final bookings = [
      sampleBooking('1'),
      sampleBooking(
        '2',
        name: 'A Very Long Customer Name That Should Not Overflow The Card',
        start: '14:00',
        end: '16:00',
        box: '2',
      ),
    ];
    final screens = <String, Widget>{
      'dashboard': const DashboardScreen(),
      'calendar': const CalendarScreen(),
      'bookings': const BookingsScreen(),
      'customers': const CustomersScreen(),
      'recurring': const RecurringScreen(),
      'reports': const ReportsScreen(),
      'expenses': const ExpensesScreen(),
      'settings': const SettingsScreen(),
      'login': const LoginScreen(),
    };

    for (final size in sizes.entries) {
      for (final screen in screens.entries) {
        testWidgets('${screen.key} fits ${size.key}', (tester) async {
          await pumpScreen(
            tester,
            screen.value,
            size: size.value,
            bookings: bookings,
            customers: const [
              Customer(
                id: '1',
                name: 'A Very Long Customer Name That Should Not Overflow',
                phone: '9876543210',
                cnt: 11,
                notes: 'Some quite long note that wraps over multiple lines on narrow screens',
              ),
            ],
            expenses: [
              Expense(
                id: '1',
                title:
                    'Long expense title that must wrap nicely on small screens',
                amount: 12345,
                category: 'Ground',
                note: 'note',
                expenseDate: todayKey(),
              ),
            ],
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
