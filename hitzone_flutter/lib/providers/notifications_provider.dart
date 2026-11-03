import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/reminders.dart';
import '../models/app_notification.dart';
import '../models/booking.dart';
import 'core_providers.dart';

/// Device-local notification list (as in the web app, which kept it in
/// localStorage). Newest first, capped at [maxItems].
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  static const _key = 'hz_n';
  static const maxItems = 100;

  /// Disambiguates ids generated within the same clock tick.
  int _sequence = 0;

  @override
  List<AppNotification> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(AppNotification.fromJson).toList();
    } catch (e) {
      debugPrint('Could not read stored notifications: $e');
      return const [];
    }
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((n) => n.toJson()).toList()));
  }

  /// Adds a notification; an existing one with the same [id] is left alone.
  void add(String title, String message, NotificationType type, {String? id}) {
    final nid = id ?? '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    if (state.any((n) => n.id == nid)) return;
    final n = AppNotification(
      id: nid,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    );
    state = [n, ...state].take(maxItems).toList();
    _persist();
  }

  void markRead(String id) {
    state = [for (final n in state) n.id == id ? n.copyWith(read: true) : n];
    _persist();
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  /// Raises "starting soon" reminders for bookings beginning within the hour.
  void syncReminders(List<Booking> bookings, DateTime now) {
    for (final b in ReminderRules.dueSoon(bookings, now)) {
      final n = ReminderRules.build(b, now);
      add(n.title, n.message, n.type, id: n.id);
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

final unreadNotificationsProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).where((n) => !n.read).length,
);
