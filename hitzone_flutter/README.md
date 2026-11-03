# HITZONE Admin — Flutter

Native Android (Flutter / Dart) admin app for **HITZONE Box Cricket**. It is a full
port of the original React + Capacitor web app and talks to the **same Supabase
project and database** — no new backend, no schema changes.

* Flutter 3.47 / Dart 3.13, Material 3, Riverpod 3 state management
* `supabase_flutter` for auth, database and realtime
* Package id `com.hitzone.admin`, display name "HITZONE Admin"

## Features

| Area | What it does |
| --- | --- |
| **Login** | Supabase email + password, validation, loading state, error banner, session persisted and restored on restart, logout |
| **Dashboard** | Today's bookings / slots / occupancy, monthly revenue & bookings, today's and monthly revenue-expense-profit, per-box performance, live 30-minute slot timeline (tap a free slot to book, tap a booking to edit, **−1hr** to shorten), weekly trend, recent / upcoming bookings, recurring groups, quick actions |
| **Calendar** | Month grid, month navigation, booking dots coloured by status, daily overview grouped by box, quick "New booking" / "Recurring" for the selected date |
| **Bookings** | Create, edit, delete, detail sheet, change status (confirmed / pending / completed / cancelled), search by name or phone, filter by status, date and box, WhatsApp / SMS buttons |
| **Recurring** | Pick customer, box, weekdays, time, number of weeks → one booking per day per week; edit (regenerates), delete group, conflict check on every generated date |
| **Customers** | List, search, add, edit, delete (blocked while bookings exist), lifetime vs active counts, VIP badge at 10+ bookings, profile with revenue / hours / favourite box / history |
| **Boxes** | Settings → number of boxes (re-enables, creates or disables boxes) and *Manage boxes* (rename, enable / disable) |
| **Expenses** | Add / edit / delete, categories, totals, category summary, top category, month total, date (today / week / month / custom) and category filters |
| **Reports** | Period filter (month / week / all / custom range), revenue, bookings, occupancy, peak hour, expenses & net profit, revenue chart, peak-hour bars, status pie, customer statistics, booking list, **CSV export** (Android share sheet) |
| **Notifications** | New booking, new customer, recurring created, conflict detected, upcoming-in-an-hour reminders; read / unread, mark all read |
| **Settings** | Dark mode, ground details & opening hours, WhatsApp / recurring / SMS templates (variable chips, reset to default), WhatsApp-SMS prompt toggle, conflict-detection toggle, change password, logout — all persisted on the device |
| **Messaging** | WhatsApp deep link and SMS composer with filled-in templates |

### Business rules (ported from the web app)

* **Conflict detection** – same date + same box, any non-cancelled booking, half-open
  intervals: 10:00–12:00 blocks 11:00–13:00 but **not** 12:00–14:00. Different boxes
  never conflict. Checked against fresh database rows right before every write.
  Recurring groups report *every* clashing date and nothing is created.
* **Amount** = hours × hourly rate (`rate_per_hour` is stored with each booking).
* **Auto-complete** – confirmed bookings whose end time has passed become `completed`.
* **Customers** – a booking creates the customer (or bumps `cnt` / `last`); deleting a
  booking lowers `cnt`. "Active" bookings are counted from the bookings table.
* **Recurring dates** – first occurrence of each selected weekday on/after the start date,
  then every 7 days, week by week (Sunday = 0).

### Intentional differences from the web app

* Booking forms are full screens (better keyboard handling) and use the native date /
  time pickers, so times are not limited to 30-minute steps.
* After saving, a bottom sheet offers **WhatsApp** and **SMS** instead of opening both
  at once (Android can only foreground one app). Opening an app is **not** reported as
  "sent" — the user still presses send in WhatsApp / Messages.
* Notifications are generated from real events (no demo data) and stored on the device,
  as before (there is no notifications table).
* Bugs in the web code were fixed rather than copied: UTC-based "today", the broken
  recurring *edit* and box-count *increase* paths, the undefined variable on booking
  delete, hard-coded 1500 rate on "−1hr", fake peak-hour chart, filters that ignored each
  other, CSV without quoting.
* Reports "Print" is not ported (no print dialog on Android); CSV export uses the share sheet.
* The login form no longer pre-fills credentials.

## Requirements

* **Flutter 3.47+** (Dart 3.13+) — <https://docs.flutter.dev/get-started/install>
* **Android Studio** (Koala or newer) with the *Flutter* and *Dart* plugins
* Android SDK Platform 35+ and a JDK 17+ (Android Studio's bundled JBR is fine)
* Accept the Android licences once: `flutter doctor --android-licenses`
* Check everything with `flutter doctor`

## Open the project in Android Studio

1. *File → Open…* and choose this folder (`hitzone_flutter`, the one containing `pubspec.yaml`).
2. When prompted, run **Pub get** (or run `flutter pub get`).
3. Pick a device in the toolbar and press **Run ▶**.

## Configure Supabase

The app ships with the Supabase URL and **publishable (anon)** key used by the original
web app (`lib/core/constants/app_config.dart`), so it works out of the box. These are public
client credentials; the data is protected by the project's **Row Level Security**, which this
app respects unchanged. To point at another project without editing code:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
```

> Never put a `service_role` key in the app.

**Tables used** (inferred from the original code, unchanged):

| Table | Columns the app reads / writes |
| --- | --- |
| `bookings` | `id`, `customer_name`, `phone`, `booking_date`, `start_time`, `end_time`, `amount`, `rate_per_hour`, `status`, `box_id`, `recurring_group_id` |
| `customers` | `id`, `name`, `phone`, `notes`, `cnt`, `last` |
| `boxes` | `id`, `name`, `active` |
| `expenses` | `id`, `title`, `amount`, `category`, `note`, `expense_date` |
| `recurring_groups` | `id`, `customer_name`, `phone`, `box_id` (FK → `boxes`), `days` (int[]), `start_time`, `end_time`, `weeks`, `rate_per_hour`, `created_at` |

Realtime must be enabled for `bookings` and `recurring_groups` (Database → Replication)
for live updates between devices; everything else works without it. The database should keep
its existing unique constraint / policies — the app also treats Postgres error `23505` as
"slot already booked". No SQL migration is required.

Sign in with the existing Supabase Auth user of the admin panel.

## Run

```bash
flutter pub get
flutter run                      # on the connected device / emulator
```

### Connect an Android device

1. Enable *Developer options* and *USB debugging* on the phone, plug it in, accept the prompt.
2. `flutter devices` should list it (or use *Device Manager* in Android Studio for an emulator).
3. `flutter run -d <device-id>`

## Tests

```bash
flutter test                                # unit + widget tests (205)
flutter analyze                             # static analysis
dart format .                               # formatting
```

* `test/core` – time maths, conflict detection, recurring generation, templates, analytics /
  revenue, expense filters, CSV, reminders
* `test/services` – booking create / edit / delete / status / −1hr, recurring create / edit /
  delete / rollback, customer rules, WhatsApp & SMS link handling (with in-memory fake repositories)
* `test/providers` – settings and notifications persistence across restarts
* `test/widget` – every screen with fake data, validation, search & filters, dark mode and
  layout checks at 320×568, 360×800, 411×891 and 800×1280

### Live Supabase integration tests

`integration_test/supabase_integration_test.dart` exercises the real backend (auth, boxes,
booking CRUD + conflicts, recurring, customers, expenses, realtime). They are **skipped
unless you pass credentials** and only create rows named `ZZ-INTEGRATION-TEST` dated 2099,
which they delete again:

```bash
flutter test integration_test/supabase_integration_test.dart -d <android-device-id> \
  --dart-define=TEST_EMAIL=you@example.com --dart-define=TEST_PASSWORD=...
```

## Build an APK

```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

The release build is currently signed with the **debug key** so it installs for testing.
Before publishing, create a keystore and configure `signingConfigs.release` in
`android/app/build.gradle.kts` (<https://docs.flutter.dev/deployment/android#signing-the-app>).

## Project structure

```
lib/
  main.dart                  entry: init Supabase + prefs, ProviderScope
  app/                       app.dart (auth gate, theme mode), theme.dart (tokens), routes.dart
  core/
    constants/app_config.dart
    utils/                   formatters, conflict_detector, recurring_generator, analytics,
                             message_templates, reminders, csv_builder, expense_filter, errors
  models/                    Booking, Customer, CricketBox, Expense, RecurringGroup, AppNotification, AppSettings
  repositories/              interface + Supabase implementation per table
  services/                  booking_service (rules), customer_service, auth, messaging,
                             realtime, export, supabase_service
  providers/                 Riverpod: data notifiers, settings, notifications, realtime,
                             navigation, AppController (all writes)
  screens/                   auth, shell, dashboard, calendar, bookings, recurring, customers,
                             expenses, reports, notifications, settings
  widgets/                   shared UI (cards, badges, pickers, booking tiles, message actions)
```

UI never touches Supabase directly: screens → `AppController` → services (business rules)
→ repositories (Supabase). Pure logic lives in `core/utils` and is unit tested.

## Permissions

Only `INTERNET`. WhatsApp and SMS are opened through intents, so no SMS permission is
needed. `<queries>` entries let the app check whether WhatsApp is installed on Android 11+.
