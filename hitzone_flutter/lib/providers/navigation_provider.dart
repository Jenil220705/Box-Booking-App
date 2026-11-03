import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppPage {
  dashboard('Dashboard', Icons.dashboard_rounded),
  calendar('Calendar', Icons.calendar_month_rounded),
  bookings('Bookings', Icons.list_alt_rounded),
  recurring('Recurring', Icons.repeat_rounded),
  customers('Customers', Icons.people_alt_rounded),
  reports('Reports', Icons.bar_chart_rounded),
  expenses('Expenses', Icons.payments_rounded),
  notifications('Notifications', Icons.notifications_rounded),
  settings('Settings', Icons.settings_rounded);

  const AppPage(this.title, this.icon);
  final String title;
  final IconData icon;
}

class CurrentPageNotifier extends Notifier<AppPage> {
  @override
  AppPage build() => AppPage.dashboard;

  void go(AppPage page) => state = page;
}

final currentPageProvider = NotifierProvider<CurrentPageNotifier, AppPage>(
  CurrentPageNotifier.new,
);
