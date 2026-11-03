import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/analytics.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../models/box.dart';
import '../../providers/app_controller.dart';
import '../../providers/data_providers.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/booking_widgets.dart';
import '../../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    return AsyncBody<List<Booking>>(
      value: bookingsAsync,
      onRetry: () => refreshAllData(ref).catchError((_) {}),
      data: (bookings) => RefreshIndicator(
        onRefresh: () => refreshAllData(ref),
        child: _DashboardBody(bookings: bookings),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hz = context.hz;
    final now = DateTime.now();
    final today = todayKey(now);
    final activeBoxes = ref.watch(activeBoxesProvider);
    final expenses = ref.watch(expensesProvider).value ?? const [];
    final recurring = ref.watch(recurringProvider).value ?? const [];
    final go = ref.read(currentPageProvider.notifier).go;

    final greeting = now.hour < 12
        ? 'Good Morning 🌅'
        : now.hour < 17
        ? 'Good Afternoon ☀️'
        : 'Good Evening 🌙';

    final todayB = bookings
        .where((b) => b.date == today && !b.isCancelled)
        .toList();
    final monthRange = DateRange.month(now);
    final monthB = Analytics.inRange(
      bookings,
      monthRange,
    ).where((b) => !b.isCancelled).toList();
    final totalSlots =
        AppConfig.dailySlotsPerBox * math.max(1, activeBoxes.length);
    final booked = todayB.length;
    final available = math.max(0, totalSlots - booked);
    final occupancy = (booked / totalSlots * 100).round().clamp(0, 100);

    final todayRevenue = Analytics.revenue(todayB);
    final monthRevenue = Analytics.revenue(monthB);
    final todayExpense = Analytics.totalExpenses(
      Analytics.expensesInRange(expenses, DateRange.today(now)),
    );
    final monthExpense = Analytics.totalExpenses(
      Analytics.expensesInRange(expenses, monthRange),
    );

    final boxStats = [
      for (final box in activeBoxes)
        (
          box: box,
          bookings: todayB.where((b) => b.boxId == box.id).length,
          revenue: Analytics.revenue(todayB.where((b) => b.boxId == box.id)),
        ),
    ];

    final weekly = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day - (6 - i));
      final key = dateKey(d);
      final count = bookings
          .where((b) => b.date == key && !b.isCancelled)
          .length;
      return (
        label: kDayNames[d.weekday % 7] + (key == today ? '★' : ''),
        count: count,
        isToday: key == today,
      );
    });

    int idOf(Booking b) => int.tryParse(b.id) ?? 0;
    final recent = ([
      ...bookings,
    ]..sort((a, b) => idOf(b).compareTo(idOf(a)))).take(4).toList();
    final upcoming =
        bookings.where((b) => !b.isCancelled && b.endsAt.isAfter(now)).toList()
          ..sort(
            (a, b) => a.date != b.date
                ? a.date.compareTo(b.date)
                : a.startTime.compareTo(b.startTime),
          );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: kPagePadding,
      children: [
        Text('$greeting, Admin', style: AppTheme.heading(context, size: 24)),
        const SizedBox(height: 4),
        Text('🏏 HITZONE Box Cricket', style: TextStyle(color: hz.tx2)),
        Text(
          '📅 ${fmtDateLong(now)}',
          style: TextStyle(color: hz.tx3, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                sub: 'Month overview',
                onTap: () => go(AppPage.calendar),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.add_circle_rounded,
                label: 'New Booking',
                sub: 'Single booking',
                primary: true,
                onTap: () => Routes.bookingForm(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.repeat_rounded,
                label: 'Recurring',
                sub: 'Weekly repeat',
                onTap: () => Routes.recurringForm(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StatGrid(
          children: [
            StatTile(
              icon: Icons.event_available_rounded,
              label: "Today's Bookings",
              value: '$booked',
              color: hz.blue,
            ),
            StatTile(
              icon: Icons.lock_clock_rounded,
              label: 'Slots Booked',
              value: '$booked',
              color: hz.red,
            ),
            StatTile(
              icon: Icons.check_circle_outline_rounded,
              label: 'Available Slots',
              value: '$available',
              color: hz.green,
            ),
            StatTile(
              icon: Icons.donut_large_rounded,
              label: 'Occupancy',
              value: '$occupancy%',
              color: hz.purple,
              footer: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: occupancy / 100,
                  minHeight: 6,
                  backgroundColor: hz.blueLight,
                  color: hz.purple,
                ),
              ),
            ),
            StatTile(
              icon: Icons.currency_rupee_rounded,
              label: 'Monthly Revenue',
              value: inr(monthRevenue),
              color: hz.yellow,
            ),
            StatTile(
              icon: Icons.sports_cricket_rounded,
              label: 'Monthly Bookings',
              value: '${monthB.length}',
              color: hz.blue,
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatGrid(
          children: [
            StatTile(
              icon: Icons.account_balance_wallet_rounded,
              label: "Today's Revenue",
              value: inr(todayRevenue),
              color: hz.green,
            ),
            StatTile(
              icon: Icons.payments_rounded,
              label: "Today's Expense",
              value: inr(todayExpense),
              color: hz.red,
            ),
            StatTile(
              icon: Icons.trending_up_rounded,
              label: "Today's Profit",
              value: inr(todayRevenue - todayExpense),
              color: hz.blue,
            ),
            StatTile(
              icon: Icons.insights_rounded,
              label: 'Monthly Profit',
              value: inr(monthRevenue - monthExpense),
              color: hz.yellow,
            ),
          ],
        ),
        const SizedBox(height: 16),
        HzCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader("🏏 Today's Box Performance"),
              const SizedBox(height: 10),
              if (boxStats.isEmpty)
                Text(
                  'No active boxes. Enable a box in Settings.',
                  style: TextStyle(color: hz.tx3),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in boxStats)
                      Container(
                        constraints: const BoxConstraints(minWidth: 140),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: hz.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.box.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bookings: ${s.bookings}',
                              style: TextStyle(color: hz.tx2),
                            ),
                            Text(
                              'Revenue: ${inr(s.revenue)}',
                              style: TextStyle(color: hz.tx2),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                'Total Revenue: ${inr(todayRevenue)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TodayTimeline(today: today, bookings: bookings, boxes: activeBoxes),
        const SizedBox(height: 16),
        HzCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('📊 Weekly Trend'),
              const SizedBox(height: 10),
              for (final d in weekly)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          d.label,
                          style: TextStyle(color: hz.tx2, fontSize: 12.5),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: math.min(100, d.count * 10 + 5) / 100,
                            minHeight: 10,
                            backgroundColor: hz.blueLight,
                            color: d.isToday
                                ? hz.blue
                                : d.count >= 8
                                ? hz.red
                                : hz.blueMid,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${d.count}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HzCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                'Recent Bookings',
                actionLabel: 'All →',
                onAction: () => go(AppPage.bookings),
              ),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Text(
                      'No bookings yet',
                      style: TextStyle(color: hz.tx3),
                    ),
                  ),
                )
              else
                for (final b in recent) BookingTile(booking: b),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HzCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                '⏰ Upcoming Bookings',
                actionLabel: 'All →',
                onAction: () => go(AppPage.bookings),
              ),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Center(
                    child: Text(
                      'No upcoming bookings',
                      style: TextStyle(color: hz.tx3),
                    ),
                  ),
                )
              else
                for (final b in upcoming.take(5)) BookingTile(booking: b),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HzCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                '🔁 Recurring Groups',
                actionLabel: 'Manage →',
                onAction: () => go(AppPage.recurring),
              ),
              if (recurring.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    child: Text(
                      'No recurring bookings yet',
                      style: TextStyle(color: hz.tx3),
                    ),
                  ),
                )
              else
                for (final r in recurring.take(3))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: AvatarCircle(name: r.name, seed: r.id, size: 38),
                    title: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${r.dayLabels.join(', ')} · ${t12(r.startTime)}–${t12(r.endTime)}',
                    ),
                    trailing: Text(
                      '${r.bookingCount} bookings',
                      style: TextStyle(
                        color: hz.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Routes.recurringForm(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.repeat_rounded),
                label: const Text('Add Recurring Booking'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final fg = primary ? Colors.white : hz.tx;
    return Material(
      color: primary ? hz.blue : hz.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: primary ? hz.blue : hz.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: primary ? Colors.white : hz.blue),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sub,
                style: TextStyle(
                  color: primary ? Colors.white70 : hz.tx3,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's 30-minute slot grid for one box. Tap a free slot to book it, tap a
/// booked slot to edit it, "-1hr" shortens a booking by an hour.
class _TodayTimeline extends ConsumerStatefulWidget {
  const _TodayTimeline({
    required this.today,
    required this.bookings,
    required this.boxes,
  });

  final String today;
  final List<Booking> bookings;
  final List<CricketBox> boxes;

  @override
  ConsumerState<_TodayTimeline> createState() => _TodayTimelineState();
}

class _TodayTimelineState extends ConsumerState<_TodayTimeline> {
  String? _boxId;
  late final ScrollController _scroll;

  static const double _rowHeight = 54;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    final open = parseMinutes(settings.opens);
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    final startIndex = math.max(0, ((nowMin - open) ~/ 30) - 1);
    _scroll = ScrollController(initialScrollOffset: startIndex * _rowHeight);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reduce(Booking b) async {
    final newEnd = minutesToTime(b.endMinutes - 60);
    final ok = await confirmDialog(
      context,
      title: 'Reduce booking?',
      message:
          "Reduce ${b.name}'s booking to ${t12(b.startTime)}–${t12(newEnd)}?",
      confirmLabel: 'Reduce',
    );
    if (!ok || !mounted) return;
    try {
      final updated = await ref.read(appControllerProvider).reduceOneHour(b);
      if (mounted) {
        showToast(
          context,
          'Booking reduced to ${t12(updated.startTime)}–${t12(updated.endTime)} ✅',
        );
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final settings = ref.watch(settingsProvider);
    final boxes = widget.boxes;
    final boxId = (_boxId != null && boxes.any((b) => b.id == _boxId))
        ? _boxId
        : (boxes.isNotEmpty ? boxes.first.id : null);

    final open = parseMinutes(settings.opens);
    final close = parseMinutes(settings.closes);
    final slots = <int>[
      for (var m = open; m < (close <= open ? 24 * 60 : close); m += 30) m,
    ];

    final todays = widget.bookings
        .where(
          (b) =>
              b.date == widget.today &&
              !b.isCancelled &&
              (boxId == null || b.boxId == boxId),
        )
        .toList();
    Widget row(int s) {
      Booking? b;
      for (final x in todays) {
        if (x.startMinutes <= s && x.endMinutes > s) {
          b = x;
          break;
        }
      }
      final label = SizedBox(
        width: 68,
        child: Text(
          t12(minutesToTime(s)),
          style: TextStyle(
            color: hz.tx2,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      if (b == null) {
        return SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              label,
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  onTap: () => Routes.bookingForm(
                    context,
                    date: widget.today,
                    from: minutesToTime(s),
                    boxId: boxId,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: hz.blueLight,
                      border: Border.all(color: hz.blue.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '🟢 Available',
                          style: TextStyle(color: hz.blueDark, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          'TAP TO BOOK',
                          style: TextStyle(
                            color: hz.blue,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final booking = b;
      // First slot a booking covers (deterministic, so lazy row building is safe).
      final first = s - 30 < booking.startMinutes || s == slots.first;
      final canReduce = booking.endMinutes - booking.startMinutes > 60;
      final isLastSlot = s + 30 >= booking.endMinutes;
      final showReduce = canReduce && (first || isLastSlot);

      return SizedBox(
        height: _rowHeight,
        child: Row(
          children: [
            label,
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                onTap: () => Routes.bookingForm(context, edit: booking),
                child: Container(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  decoration: BoxDecoration(
                    color: hz.red.withValues(alpha: first ? 0.14 : 0.08),
                    border: Border.all(color: hz.red.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: first
                            ? Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(text: '🔴 '),
                                    TextSpan(
                                      text: booking.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '  ${t12(booking.startTime)} – ${t12(booking.endTime)} · ${booking.hours}h',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: hz.tx2,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              )
                            : Text(
                                '↳ ${booking.name}',
                                style: TextStyle(color: hz.red, fontSize: 12),
                              ),
                      ),
                      if (showReduce)
                        SizedBox(
                          height: 30,
                          child: FilledButton(
                            onPressed: () => _reduce(booking),
                            style: FilledButton.styleFrom(
                              backgroundColor: hz.red,
                              minimumSize: const Size(0, 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('−1hr'),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            first ? '✏️ EDIT' : 'BOOKED',
                            style: TextStyle(
                              color: hz.red,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return HzCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            "📅 Today's Slot Status",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legend(hz.red.withValues(alpha: 0.3), 'Booked', hz),
                const SizedBox(width: 10),
                _legend(hz.blueLight, 'Free', hz, border: hz.blue),
              ],
            ),
          ),
          if (boxes.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final b in boxes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(b.name),
                        selected: b.id == boxId,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: b.id == boxId ? Colors.white : hz.tx2,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _boxId = b.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (boxId == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No active box. Enable a box in Settings.',
                style: TextStyle(color: hz.tx3),
              ),
            )
          else
            SizedBox(
              height: 400,
              child: ListView.builder(
                controller: _scroll,
                itemExtent: _rowHeight,
                itemCount: slots.length,
                itemBuilder: (_, i) => row(slots[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text, HzColors hz, {Color? border}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: border ?? hz.red.withValues(alpha: 0.6),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: hz.tx2, fontSize: 12)),
    ],
  );
}
