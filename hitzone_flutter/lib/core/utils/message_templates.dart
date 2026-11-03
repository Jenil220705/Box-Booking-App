import '../utils/formatters.dart';

/// WhatsApp / SMS message templates with `{variable}` placeholders.
class MessageTemplates {
  const MessageTemplates._();

  static const String defaultWhatsApp =
      'Hello {name},\n\n🏏 *HITZONE Box Cricket*\n\nBooking Confirmed ✅\n\n📅 Date: {date}\n⏰ Time: {from} – {to}\n\nPlease arrive 10 mins early.\n📍 HITZONE Ground, Rajkot\n\n_HITZONE Admin_';

  static const String defaultRecurringWhatsApp =
      'Hello {name},\n\n🏏 *HITZONE Box Cricket*\n\nYour recurring booking has been confirmed ✅\n\n📅 Starting Date: {date}\n⏰ Time: {from} - {to}\n📆 Duration: {weeks} Weeks\n\nPlease arrive 10 mins early.\n\n_HITZONE Admin_';

  static const String defaultSms =
      'Hi {name}, HITZONE Box Cricket booking confirmed! Date: {date}, Time: {from}-{to}. Arrive 10 mins early. Rajkot.';

  static const List<String> bookingVariables = ['name', 'date', 'from', 'to'];
  static const List<String> recurringVariables = [
    'name',
    'date',
    'from',
    'to',
    'weeks',
    'days',
    'dates',
  ];

  static final RegExp _placeholder = RegExp(r'\{(\w+)\}');

  /// Replaces every `{key}` found in [vars]; unknown placeholders are left as
  /// they are so a typo in a template is visible rather than silently lost.
  static String fill(String template, Map<String, String> vars) {
    return template.replaceAllMapped(
      _placeholder,
      (m) => vars[m.group(1)] ?? m.group(0)!,
    );
  }

  static Map<String, String> bookingVars({
    required String name,
    required String date,
    required String from,
    required String to,
  }) {
    return {
      'name': name.isEmpty ? 'Customer' : name,
      'date': fmtDate(date),
      'from': t12(from),
      'to': t12(to),
    };
  }

  static Map<String, String> recurringVars({
    required String name,
    required String startDate,
    required String from,
    required String to,
    required int weeks,
    required List<int> days,
    List<String> dates = const [],
  }) {
    return {
      ...bookingVars(name: name, date: startDate, from: from, to: to),
      'weeks': weeks.toString(),
      'days': days.map((d) => kDayNames[d % 7]).join(', '),
      'dates': dates.map((d) => '📅 ${fmtDate(d)}').join('\n'),
    };
  }

  /// Generic message used from the customer list (original wording).
  static String customerGreeting(String name) =>
      'Hello $name,\n\n🏏 This is HITZONE Box Cricket.\n\nThank you! For bookings: +91 98765 43210\n\n_HITZONE Admin_';

  /// Short reminder used from the bookings list (original wording).
  static String bookingReminder({
    required String name,
    required String date,
    required String from,
    required String to,
  }) =>
      'Hello $name,\n\n🏏 *HITZONE Box Cricket*\n\n📅 Date: ${fmtDate(date)}\n⏰ ${t12(from)} – ${t12(to)}\n\nSee you at HITZONE! 🏟️';
}
