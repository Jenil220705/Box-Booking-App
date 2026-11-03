import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../providers/data_providers.dart';
import '../../widgets/booking_widgets.dart';
import '../../widgets/common.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late String _selected = todayKey();

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _goToday() => setState(() {
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _selected = todayKey();
  });

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final bookingsAsync = ref.watch(bookingsProvider);
    final activeBoxes = ref.watch(activeBoxesProvider);
    final activeIds = activeBoxes.map((b) => b.id).toSet();

    return AsyncBody<List<Booking>>(
      value: bookingsAsync,
      onRetry: () =>
          ref.read(bookingsProvider.notifier).refresh().catchError((_) {}),
      data: (all) {
        // Same visibility rule as the web app: no cancelled bookings, only active boxes.
        final visible = all
            .where((b) => !b.isCancelled && activeIds.contains(b.boxId))
            .toList();
        final byDate = <String, List<Booking>>{};
        for (final b in visible) {
          byDate.putIfAbsent(b.date, () => []).add(b);
        }

        final first = DateTime(_month.year, _month.month, 1);
        final leading = first.weekday % 7;
        final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
        final today = todayKey();

        final dayList = [...(byDate[_selected] ?? const <Booking>[])]
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return RefreshIndicator(
          onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: kPagePadding,
            children: [
              HzCard(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Previous month',
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () => _shiftMonth(-1),
                        ),
                        Expanded(
                          child: Text(
                            '${kMonthNames[_month.month - 1]} ${_month.year}',
                            textAlign: TextAlign.center,
                            style: AppTheme.heading(context, size: 18),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next month',
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () => _shiftMonth(1),
                        ),
                        IconButton(
                          tooltip: 'Today',
                          icon: const Icon(Icons.today_rounded),
                          onPressed: _goToday,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (final d in kDayNames)
                          Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  color: hz.tx3,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: leading + daysInMonth,
                      itemBuilder: (context, i) {
                        if (i < leading) return const SizedBox.shrink();
                        final day = i - leading + 1;
                        final key = dateKey(
                          DateTime(_month.year, _month.month, day),
                        );
                        return _DayCell(
                          day: day,
                          isToday: key == today,
                          isSelected: key == _selected,
                          bookings: byDate[key] ?? const [],
                          onTap: () => setState(() => _selected = key),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        for (final s in BookingStatus.values.where(
                          (s) => s != BookingStatus.cancelled,
                        ))
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: hz.statusColors(s).$1,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                s.label,
                                style: TextStyle(color: hz.tx2, fontSize: 11.5),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HzCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader('📅 ${fmtDate(_selected)}'),
                    const SizedBox(height: 4),
                    Text(
                      '${dayList.length} booking${dayList.length == 1 ? '' : 's'}',
                      style: TextStyle(color: hz.tx2),
                    ),
                    const SizedBox(height: 8),
                    if (activeBoxes.length > 1)
                      for (final box in activeBoxes) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: Text(
                            '🏏 ${box.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        ..._tiles(
                          dayList.where((b) => b.boxId == box.id).toList(),
                          hz,
                        ),
                      ]
                    else
                      ..._tiles(dayList, hz),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                Routes.bookingForm(context, date: _selected),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('New Booking'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                Routes.recurringForm(context, date: _selected),
                            icon: const Icon(Icons.repeat_rounded),
                            label: const Text('Recurring'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _tiles(List<Booking> list, HzColors hz) {
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text('No bookings', style: TextStyle(color: hz.tx3)),
        ),
      ];
    }
    return [for (final b in list) BookingTile(booking: b, showDate: false)];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.bookings,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final List<Booking> bookings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final dots = bookings.take(3).toList();
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? hz.blue
                : (bookings.isNotEmpty ? hz.blueLight : null),
            border: Border.all(
              color: isToday ? hz.blue : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : hz.tx,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final b in dots)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : hz.statusColors(b.status).$1,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
              if (bookings.length > 3)
                Text(
                  '+${bookings.length - 3}',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isSelected ? Colors.white : hz.tx3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
