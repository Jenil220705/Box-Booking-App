/// Backend configuration.
///
/// The Supabase URL and the *publishable (anon)* key are public client
/// credentials – row level security on the Supabase project is what protects
/// the data. They default to the values used by the original HITZONE web app
/// and can be overridden at build time without touching the source:
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// NEVER put a `service_role` key in this app.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kjlfrqogkjubudrmvfqx.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_fy5qQUvoBXpycDCJztv4Rw_X-0sLBDH',
  );

  /// Country calling code prepended to 10 digit Indian mobile numbers.
  static const String countryCode = '91';

  /// Slots per box used for the dashboard "available slots" / occupancy tiles
  /// (the original app used a fixed 12).
  static const int dailySlotsPerBox = 12;

  /// Hourly rate pre-filled in the booking form (original default).
  static const double defaultHourlyRate = 1500;

  static const List<String> expenseCategories = [
    'Ground',
    'Electricity',
    'Water',
    'Salary',
    'Maintenance',
    'Marketing',
    'Other',
  ];
}
