import '../core/utils/message_templates.dart';

/// User preferences, persisted on the device.
class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.waTemplate = MessageTemplates.defaultWhatsApp,
    this.recurringWaTemplate = MessageTemplates.defaultRecurringWhatsApp,
    this.smsTemplate = MessageTemplates.defaultSms,
    this.groundName = 'HITZONE Box Cricket',
    this.address = 'Nr. Race Course, Rajkot, Gujarat',
    this.contact = '+91 98765 43210',
    this.opens = '06:00',
    this.closes = '23:59',
    this.whatsappAlerts = true,
    this.conflictDetection = true,
  });

  final bool darkMode;
  final String waTemplate;
  final String recurringWaTemplate;
  final String smsTemplate;
  final String groundName;
  final String address;
  final String contact;
  final String opens;
  final String closes;

  /// Offer the WhatsApp / SMS confirmation after a booking is saved.
  final bool whatsappAlerts;

  /// Reject bookings that overlap an existing one on the same box.
  final bool conflictDetection;

  AppSettings copyWith({
    bool? darkMode,
    String? waTemplate,
    String? recurringWaTemplate,
    String? smsTemplate,
    String? groundName,
    String? address,
    String? contact,
    String? opens,
    String? closes,
    bool? whatsappAlerts,
    bool? conflictDetection,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      waTemplate: waTemplate ?? this.waTemplate,
      recurringWaTemplate: recurringWaTemplate ?? this.recurringWaTemplate,
      smsTemplate: smsTemplate ?? this.smsTemplate,
      groundName: groundName ?? this.groundName,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      opens: opens ?? this.opens,
      closes: closes ?? this.closes,
      whatsappAlerts: whatsappAlerts ?? this.whatsappAlerts,
      conflictDetection: conflictDetection ?? this.conflictDetection,
    );
  }
}
