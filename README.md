# HITZONE Box Cricket — Admin Panel

React + Capacitor Android application converted from the original HTML project.

## Prerequisites
- Node.js >= 18
- Android Studio (for APK build)
- Java JDK 17+

## Quick Start

```bash
npm install
npm run dev          # Start dev server at http://localhost:5173
```

## Build & Deploy to Android

```bash
npm run build        # Build React app → dist/
npx cap sync android # Sync to Android project
npx cap open android # Open in Android Studio → Build APK
```

Or use the combined script:
```bash
npm run android
```

## Login Credentials
- Email: `admin@hitzone.com`
- Password: `admin123`

## Features
- Dashboard with live slot timeline
- Calendar view (monthly)
- Booking management (add / edit / delete / WhatsApp / SMS)
- Recurring bookings (weekly repeat, multiple days)
- Customer management
- Reports & analytics with CSV export
- Notifications panel
- Settings (price, templates, dark mode)
- Conflict detection
- WhatsApp & SMS auto-send on booking

## Project Structure
```
src/
  App.jsx                  # Root shell + modal orchestration
  main.jsx                 # Entry point
  context/
    AppContext.jsx          # Global state (bookings, customers, notifications)
  components/
    AuthPage.jsx            # Login screen
    Sidebar.jsx             # Navigation sidebar
    Navbar.jsx              # Top header bar
    Toast.jsx               # Toast notifications
    BookingModal.jsx        # Add/edit booking modal
    RecurModal.jsx          # Recurring booking modal
    CustModal.jsx           # Customer add/edit modal
  pages/
    Dashboard.jsx           # Main dashboard
    CalendarPage.jsx        # Monthly calendar
    BookingsPage.jsx        # All bookings table
    RecurringPage.jsx       # Recurring groups
    CustomersPage.jsx       # Customer cards
    ReportsPage.jsx         # Analytics
    NotificationsPage.jsx   # Notification list
    SettingsPage.jsx        # App settings
  styles/
    global.css              # All styles (pixel-perfect match to original HTML)
  utils/
    helpers.js              # Shared utility functions
android/                   # Capacitor Android project (APK-ready)
```
