import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_config.dart';

class SupabaseService {
  const SupabaseService._();

  /// Initialises the SDK. Sessions are persisted by the SDK itself (shared
  /// preferences), which gives automatic session restoration on app start.
  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
