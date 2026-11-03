import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Postgres change subscriptions for `bookings` and `recurring_groups`.
class RealtimeService {
  RealtimeService(this._db);

  final SupabaseClient _db;
  RealtimeChannel? _channel;

  void start({
    required VoidCallback onBookingsChanged,
    required VoidCallback onRecurringChanged,
    void Function(RealtimeSubscribeStatus status)? onStatus,
  }) {
    stop();
    _channel = _db
        .channel('hitzone-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => onBookingsChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'recurring_groups',
          callback: (_) => onRecurringChanged(),
        )
        .subscribe((status, error) {
          if (error != null) debugPrint('Realtime error: $error');
          onStatus?.call(status);
        });
  }

  void stop() {
    final channel = _channel;
    if (channel != null) {
      _db.removeChannel(channel);
      _channel = null;
    }
  }
}
