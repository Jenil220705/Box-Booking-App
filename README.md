# HITZONE Box Cricket — Admin App

Native Android admin app (Flutter / Dart) for HITZONE Box Cricket: bookings,
recurring bookings, calendar, customers, boxes, expenses, reports, notifications and
WhatsApp / SMS confirmations, backed by Supabase.

The app lives in [`hitzone_flutter/`](hitzone_flutter) — open that folder in Android Studio.
See [`hitzone_flutter/README.md`](hitzone_flutter/README.md) for setup, Supabase
configuration, running, testing and building the APK.

It replaced the earlier React + Capacitor version (removed from this branch; it remains in
the git history before the `flutter-migration` branch). The Supabase project and database
are unchanged.

```bash
cd hitzone_flutter
flutter pub get
flutter run
```
