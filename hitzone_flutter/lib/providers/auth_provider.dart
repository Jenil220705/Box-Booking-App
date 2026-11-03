import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core_providers.dart';

/// Current Supabase session (null = signed out). Persisted sessions are
/// restored by the SDK, so this is already non-null on a warm start.
final authSessionProvider = StreamProvider<Session?>(
  (ref) => ref.watch(authServiceProvider).sessionChanges(),
);
