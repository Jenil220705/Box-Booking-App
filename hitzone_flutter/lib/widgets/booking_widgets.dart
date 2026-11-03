import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../core/utils/errors.dart';
import '../core/utils/formatters.dart';
import '../core/utils/message_templates.dart';
import '../models/booking.dart';
import '../providers/app_controller.dart';
import '../providers/data_providers.dart';
import 'common.dart';
import 'message_actions.dart';

/// Shared booking operations used from several screens.
class BookingActions {
  const BookingActions._();

  static Future<bool> delete(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete booking?',
      message:
          '${booking.name} · ${fmtDate(booking.date)} ${t12(booking.startTime)}–${t12(booking.endTime)}',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return false;
    try {
      await ref.read(appControllerProvider).deleteBooking(booking);
      if (context.mounted) showToast(context, 'Deleted ✅');
      return true;
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
      return false;
    }
  }

  static Future<void> whatsApp(
    BuildContext context,
    WidgetRef ref,
    Booking b,
  ) => MessageActions.whatsApp(
    context,
    ref,
    b.phone,
    MessageTemplates.bookingReminder(
      name: b.name,
      date: b.date,
      from: b.startTime,
      to: b.endTime,
    ),
  );

  static Future<void> sms(BuildContext context, WidgetRef ref, Booking b) =>
      MessageActions.sms(
        context,
        ref,
        b.phone,
        MessageActions.bookingSmsText(
          ref,
          name: b.name,
          date: b.date,
          from: b.startTime,
          to: b.endTime,
        ),
      );
}

/// Full booking card (bookings list).
class BookingCard extends ConsumerWidget {
  const BookingCard({super.key, required this.booking, required this.index});

  final Booking booking;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hz = context.hz;
    final showBox = ref.watch(activeBoxesProvider).length > 1;
    final boxName = ref.watch(boxNameResolverProvider)(booking.boxId);

    Widget cell(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: hz.tx3, fontSize: 11.5)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ],
      ),
    );

    return HzCard(
      onTap: () => showBookingDetail(context, booking.id),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCircle(name: booking.name, seed: booking.id),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '📱 ${booking.phone}',
                      style: TextStyle(color: hz.tx2, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: StatusBadge(booking.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cell('Date', fmtDate(booking.date)),
                cell(
                  'Time',
                  '${t12(booking.startTime)} – ${t12(booking.endTime)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cell('Amount', inr(booking.amount)),
                cell('Duration', '${booking.hours}h'),
                if (showBox) cell('Box', boxName),
              ],
            ),
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (booking.isRecurring)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.repeat_rounded, size: 18, color: hz.tx3),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Routes.bookingForm(context, edit: booking),
              ),
              IconButton(
                tooltip: 'WhatsApp',
                icon: Icon(Icons.chat_rounded, color: hz.green),
                onPressed: () => BookingActions.whatsApp(context, ref, booking),
              ),
              IconButton(
                tooltip: 'SMS',
                icon: Icon(Icons.sms_rounded, color: hz.blue),
                onPressed: () => BookingActions.sms(context, ref, booking),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete_rounded, color: hz.red),
                onPressed: () => BookingActions.delete(context, ref, booking),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact row used on the dashboard and calendar.
class BookingTile extends ConsumerWidget {
  const BookingTile({super.key, required this.booking, this.showDate = true});

  final Booking booking;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hz = context.hz;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: () => showBookingDetail(context, booking.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            AvatarCircle(name: booking.name, seed: booking.id, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showDate)
                    Text(
                      fmtDate(booking.date),
                      style: TextStyle(color: hz.tx3, fontSize: 12.5),
                    ),
                ],
              ),
            ),
            // Flexible + FittedBox: the time range shrinks on narrow phones
            // instead of overflowing the card.
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${t12(booking.startTime)}–${t12(booking.endTime)}',
                      style: AppTheme.heading(context, size: 13),
                    ),
                  ),
                  const SizedBox(height: 3),
                  StatusBadge(booking.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with every booking detail, status change and actions.
/// It looks the booking up by id so it always shows fresh data.
Future<void> showBookingDetail(BuildContext context, String bookingId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BookingDetailSheet(bookingId: bookingId),
  );
}

class _BookingDetailSheet extends ConsumerWidget {
  const _BookingDetailSheet({required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hz = context.hz;
    final bookings = ref.watch(bookingsProvider).value ?? const <Booking>[];
    final matches = bookings.where((b) => b.id == bookingId);
    if (matches.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(
          icon: Icons.event_busy_rounded,
          message: 'This booking no longer exists.',
        ),
      );
    }
    final b = matches.first;
    final boxName = ref.watch(boxNameResolverProvider)(b.boxId);

    Future<void> setStatus(BookingStatus s) async {
      if (s == b.status) return;
      try {
        await ref.read(appControllerProvider).changeStatus(b, s);
        if (context.mounted) showToast(context, 'Status changed to ${s.label}');
      } catch (e) {
        if (context.mounted) showToast(context, errorMessage(e), error: true);
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AvatarCircle(name: b.name, seed: b.id, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name, style: AppTheme.heading(context, size: 19)),
                      Text('📱 ${b.phone}', style: TextStyle(color: hz.tx2)),
                    ],
                  ),
                ),
                StatusBadge(b.status),
              ],
            ),
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.event_rounded,
              label: 'Date',
              value: fmtDate(b.date),
            ),
            InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Time',
              value: '${t12(b.startTime)} – ${t12(b.endTime)} (${b.hours}h)',
            ),
            InfoRow(
              icon: Icons.sports_cricket_rounded,
              label: 'Box',
              value: boxName,
            ),
            InfoRow(
              icon: Icons.payments_rounded,
              label: 'Amount',
              value: '${inr(b.amount)}  (${inr(b.effectiveRate)}/h)',
            ),
            if (b.isRecurring)
              const InfoRow(
                icon: Icons.repeat_rounded,
                label: 'Type',
                value: 'Part of a recurring group',
              ),
            const SizedBox(height: 12),
            Text(
              'Change status',
              style: TextStyle(color: hz.tx2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in BookingStatus.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: b.status == s,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: b.status == s ? Colors.white : hz.tx2,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setStatus(s),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Routes.bookingForm(context, edit: b);
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => BookingActions.whatsApp(context, ref, b),
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => BookingActions.sms(context, ref, b),
                    icon: const Icon(Icons.sms_rounded),
                    label: const Text('SMS'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: hz.red),
                    onPressed: () async {
                      final deleted = await BookingActions.delete(
                        context,
                        ref,
                        b,
                      );
                      if (deleted && context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
