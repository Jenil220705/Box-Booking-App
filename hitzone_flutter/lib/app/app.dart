import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../providers/navigation_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/shell/home_shell.dart';
import 'theme.dart';

class HitzoneApp extends ConsumerWidget {
  const HitzoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(settingsProvider.select((s) => s.darkMode));
    return MaterialApp(
      title: 'HITZONE Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

/// Shows the login screen or the app depending on the Supabase session, and
/// wipes cached data when the user signs out.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authSessionProvider, (previous, next) {
      final wasSignedIn = previous?.value != null;
      if (wasSignedIn && next.value == null) {
        ref.invalidate(bookingsProvider);
        ref.invalidate(customersProvider);
        ref.invalidate(boxesProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(recurringProvider);
        ref.invalidate(currentPageProvider);
        ref.invalidate(notificationsProvider);
      }
    });

    final session = ref.watch(authSessionProvider);
    return session.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LoginScreen(),
      data: (s) => s == null ? const LoginScreen() : const HomeShell(),
    );
  }
}
