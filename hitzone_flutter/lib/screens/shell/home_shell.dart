import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/booking.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import '../bookings/bookings_screen.dart';
import '../calendar/calendar_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../expenses/expenses_screen.dart';
import '../notifications/notifications_screen.dart';
import '../recurring/recurring_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

/// Signed-in shell: app bar, drawer (all pages), bottom navigation (main
/// pages), page-specific FAB, Android back-button handling.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _reminderTimer;
  DateTime? _lastBackPress;

  /// Pages reachable from the bottom bar; everything else is under "More".
  static const _bottomPages = [
    AppPage.dashboard,
    AppPage.calendar,
    AppPage.bookings,
    AppPage.customers,
  ];

  @override
  void initState() {
    super.initState();
    // Kick off every load and start realtime as soon as the shell is shown.
    ref.read(boxesProvider);
    ref.read(customersProvider);
    ref.read(expensesProvider);
    ref.read(recurringProvider);
    ref.read(bookingsProvider);
    ref.read(realtimeProvider);
    _reminderTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _syncReminders(),
    );
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _syncReminders() {
    final bookings = ref.read(bookingsProvider).value;
    if (bookings == null) return;
    ref
        .read(notificationsProvider.notifier)
        .syncReminders(bookings, DateTime.now());
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again.',
      confirmLabel: 'Log out',
    );
    if (!ok) return;
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (mounted) showToast(context, 'Logout failed: $e', error: true);
    }
  }

  void _handleBack() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
      return;
    }
    if (ref.read(currentPageProvider) != AppPage.dashboard) {
      ref.read(currentPageProvider.notifier).go(AppPage.dashboard);
      return;
    }
    // On the dashboard: press back twice to leave the app.
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      // PopScope(canPop: false) would swallow maybePop(), so leave explicitly.
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    showToast(context, 'Press back again to exit');
  }

  Widget _body(AppPage page) {
    return switch (page) {
      AppPage.dashboard => const DashboardScreen(),
      AppPage.calendar => const CalendarScreen(),
      AppPage.bookings => const BookingsScreen(),
      AppPage.recurring => const RecurringScreen(),
      AppPage.customers => const CustomersScreen(),
      AppPage.reports => const ReportsScreen(),
      AppPage.expenses => const ExpensesScreen(),
      AppPage.notifications => const NotificationsScreen(),
      AppPage.settings => const SettingsScreen(),
    };
  }

  Widget? _fab(AppPage page) {
    switch (page) {
      case AppPage.dashboard:
      case AppPage.bookings:
        return FloatingActionButton.extended(
          onPressed: () => Routes.bookingForm(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Booking'),
        );
      case AppPage.recurring:
        return FloatingActionButton.extended(
          onPressed: () => Routes.recurringForm(context),
          icon: const Icon(Icons.repeat_rounded),
          label: const Text('Create Recurring'),
        );
      case AppPage.customers:
        return FloatingActionButton.extended(
          onPressed: () => Routes.customerForm(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add Customer'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(currentPageProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final dark = ref.watch(settingsProvider.select((s) => s.darkMode));
    final hz = context.hz;

    // Raise reminders as soon as bookings (re)load.
    ref.listen(bookingsProvider, (_, next) => _syncReminders());

    final bottomIndex = _bottomPages.indexOf(page);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(page.title, style: AppTheme.heading(context, size: 20)),
          actions: [
            IconButton(
              tooltip: dark ? 'Light mode' : 'Dark mode',
              icon: Icon(
                dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
              onPressed: () =>
                  ref.read(settingsProvider.notifier).setDarkMode(!dark),
            ),
            IconButton(
              tooltip: 'Notifications',
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_rounded),
              ),
              onPressed: () => ref
                  .read(currentPageProvider.notifier)
                  .go(AppPage.notifications),
            ),
            const SizedBox(width: 4),
          ],
        ),
        drawer: _AppDrawer(onLogout: _logout),
        body: SafeArea(top: false, child: _body(page)),
        floatingActionButton: _fab(page),
        bottomNavigationBar: NavigationBar(
          selectedIndex: bottomIndex == -1 ? _bottomPages.length : bottomIndex,
          onDestinationSelected: (i) {
            if (i == _bottomPages.length) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              ref.read(currentPageProvider.notifier).go(_bottomPages[i]);
            }
          },
          destinations: [
            for (final p in _bottomPages)
              NavigationDestination(icon: Icon(p.icon), label: p.title),
            NavigationDestination(
              icon: Icon(
                Icons.menu_rounded,
                color: bottomIndex == -1 ? hz.blueDark : null,
              ),
              label: bottomIndex == -1 ? page.title : 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentPageProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final pending =
        ref
            .watch(bookingsProvider)
            .value
            ?.where((b) => b.status == BookingStatus.pending)
            .length ??
        0;
    final user = ref.watch(authServiceProvider).currentUser;
    final hz = context.hz;

    Widget item(AppPage page, {int badge = 0}) {
      final selected = page == current;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: ListTile(
          selected: selected,
          selectedTileColor: hz.blue,
          selectedColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          leading: Icon(page.icon),
          title: Text(
            page.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: badge > 0 ? Badge(label: Text('$badge')) : null,
          onTap: () {
            Navigator.pop(context);
            ref.read(currentPageProvider.notifier).go(page);
          },
        ),
      );
    }

    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: hz.tx3,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hz.blue,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Text('🏏', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HITZONE',
                        style: AppTheme.heading(context, size: 17),
                      ),
                      Text(
                        'BOX CRICKET',
                        style: TextStyle(
                          color: hz.tx3,
                          fontSize: 10,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  label('Main'),
                  item(AppPage.dashboard),
                  item(AppPage.calendar),
                  item(AppPage.bookings, badge: pending),
                  item(AppPage.recurring),
                  label('Management'),
                  item(AppPage.customers),
                  item(AppPage.reports),
                  item(AppPage.expenses),
                  label('System'),
                  item(AppPage.notifications, badge: unread),
                  item(AppPage.settings),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: hz.blue,
                foregroundColor: Colors.white,
                child: const Text('HA'),
              ),
              title: const Text(
                'Hitzone Admin',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                user?.email ?? 'Owner · Full Access',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Log out',
                icon: Icon(Icons.logout_rounded, color: hz.red),
                onPressed: () {
                  Navigator.pop(context);
                  onLogout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
