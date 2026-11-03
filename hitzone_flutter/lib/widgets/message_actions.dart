import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/message_templates.dart';
import '../models/booking.dart';
import '../models/recurring_group.dart';
import '../providers/core_providers.dart';
import '../providers/settings_provider.dart';
import '../services/messaging_service.dart';
import 'common.dart';

/// Opens WhatsApp / SMS with a pre-filled message and tells the user exactly
/// what happened. "Opened" never claims the message was sent.
class MessageActions {
  const MessageActions._();

  static void _report(
    ScaffoldMessengerState messenger,
    MessagingResult result,
    String app,
  ) {
    switch (result) {
      case MessagingResult.opened:
        showToastWith(
          messenger,
          '$app opened with the message ready — press send there to deliver it.',
        );
      case MessagingResult.unavailable:
        showToastWith(
          messenger,
          'Could not open $app. Is it installed on this phone?',
          error: true,
        );
      case MessagingResult.invalidNumber:
        showToastWith(
          messenger,
          'This mobile number is not valid.',
          error: true,
        );
    }
  }

  static Future<void> whatsApp(
    BuildContext context,
    WidgetRef ref,
    String phone,
    String message,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(messagingServiceProvider);
    _report(messenger, await service.openWhatsApp(phone, message), 'WhatsApp');
  }

  static Future<void> sms(
    BuildContext context,
    WidgetRef ref,
    String phone,
    String message,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(messagingServiceProvider);
    _report(messenger, await service.openSms(phone, message), 'Messages');
  }

  static String bookingWhatsAppText(
    WidgetRef ref, {
    required String name,
    required String date,
    required String from,
    required String to,
  }) => MessageTemplates.fill(
    ref.read(settingsProvider).waTemplate,
    MessageTemplates.bookingVars(name: name, date: date, from: from, to: to),
  );

  static String bookingSmsText(
    WidgetRef ref, {
    required String name,
    required String date,
    required String from,
    required String to,
  }) => MessageTemplates.fill(
    ref.read(settingsProvider).smsTemplate,
    MessageTemplates.bookingVars(name: name, date: date, from: from, to: to),
  );

  static String recurringWhatsAppText(
    WidgetRef ref,
    RecurringDraft draft,
    List<Booking> bookings,
  ) => MessageTemplates.fill(
    ref.read(settingsProvider).recurringWaTemplate,
    MessageTemplates.recurringVars(
      name: draft.name,
      startDate: bookings.isNotEmpty ? bookings.first.date : draft.startDate,
      from: draft.startTime,
      to: draft.endTime,
      weeks: draft.weeks,
      days: draft.days,
      dates: bookings.map((b) => b.date).toList(),
    ),
  );

  /// Post-save prompt: lets the owner send the confirmation by WhatsApp and/or
  /// SMS. (Android cannot open two apps at once, so the original "auto-open
  /// both" flow became an explicit choice.)
  static Future<void> offerConfirmation(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String phone,
    required String whatsAppText,
    String? smsText,
  }) async {
    if (!ref.read(settingsProvider).whatsappAlerts) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Send the customer a confirmation. Your messaging app opens with the text ready — you still press send there.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await whatsApp(context, ref, phone, whatsAppText);
                },
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Open WhatsApp'),
              ),
              if (smsText != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await sms(context, ref, phone, smsText);
                  },
                  icon: const Icon(Icons.sms_rounded),
                  label: const Text('Open SMS'),
                ),
              ],
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
