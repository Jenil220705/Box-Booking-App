import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/analytics.dart';
import '../../core/utils/csv_builder.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';

enum _Period {
  month('This Month'),
  week('This Week'),
  all('All Time'),
  custom('Custom');

  const _Period(this.label);
  final String label;
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _Period _period = _Period.month;
  String _from = '';
  String _to = '';
  bool _exporting = false;

  DateRange? _range(DateTime now) => switch (_period) {
    _Period.month => DateRange.month(now),
    _Period.week => DateRange.week(now),
    _Period.all => null,
    _Period.custom =>
      (_from.isNotEmpty && _to.isNotEmpty && _from.compareTo(_to) <= 0)
          ? DateRange(_from, _to)
          : null,
  };

  Future<void> _export(List<Booking> list) async {
    if (list.isEmpty) {
      showToast(context, 'Nothing to export for this period', error: true);
      return;
    }
    setState(() => _exporting = true);
    try {
      final csv = CsvBuilder.bookings(
        list,
        boxName: ref.read(boxNameResolverProvider),
      );
      await ref.read(exportServiceProvider).shareCsv(csv);
    } catch (e) {
      if (mounted) {
        showToast(context, 'Export failed: ${errorMessage(e)}', error: true);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final bookingsAsync = ref.watch(bookingsProvider);
    final expenses = ref.watch(expensesProvider).value ?? const [];
    final customers = ref.watch(customersProvider).value ?? const [];
    final settings = ref.watch(settingsProvider);
    final boxCount = ref.watch(activeBoxesProvider).length;
    final boxName = ref.watch(boxNameResolverProvider);

    return AsyncBody<List<Booking>>(
      value: bookingsAsync,
      onRetry: () =>
          ref.read(bookingsProvider.notifier).refresh().catchError((_) {}),
      data: (all) {
        final now = DateTime.now();
        final customRangeInvalid =
            _period == _Period.custom && _range(now) == null;
        final range = _range(now);

        final inPeriod = customRangeInvalid
            ? <Booking>[]
            : Analytics.inRange(all, range);
        final active = Analytics.active(inPeriod);
        final revenue = Analytics.revenue(active);
        final periodExpenses = range == null
            ? expenses
            : Analytics.expensesInRange(expenses, range);
        final expenseTotal = customRangeInvalid
            ? 0.0
            : Analytics.totalExpenses(periodExpenses);

        // Span used for occupancy / trend: the chosen range, else first..last booking.
        DateRange? span = range;
        if (span == null && active.isNotEmpty) {
          final dates = active.map((b) => b.date).toList()..sort();
          span = DateRange(dates.first, dates.last);
        }
        final openMinutes =
            (parseMinutes(settings.closes) - parseMinutes(settings.opens))
                .clamp(60, 24 * 60);
        final occupancy = span == null
            ? 0.0
            : Analytics.occupancyPercent(
                bookings: active,
                days: span.days,
                openMinutesPerDay: openMinutes,
                boxCount: boxCount,
              );
        final peak = Analytics.peakHour(active);

        final statusCounts = Analytics.statusCounts(inPeriod);
        final totals = Analytics.customerTotals(active);
        final topCustomers =
            (totals.entries.toList()
                  ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue)))
                .take(5)
                .toList();
        final repeat = totals.values.where((t) => t.bookings >= 2).length;

        final listForTable = ([
          ...active,
        ]..sort((a, b) => b.date.compareTo(a.date))).take(20).toList();

        return RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.read(bookingsProvider.notifier).refresh(),
            ref.read(expensesProvider.notifier).refresh(),
            ref.read(customersProvider.notifier).refresh(),
          ]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: kPagePadding,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _Period.values)
                    ChoiceChip(
                      label: Text(p.label),
                      selected: _period == p,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _period == p ? Colors.white : hz.tx2,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _period = p),
                    ),
                ],
              ),
              if (_period == _Period.custom) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DateField(
                        label: 'From',
                        value: _from,
                        onChanged: (v) => setState(() => _from = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DateField(
                        label: 'To',
                        value: _to,
                        onChanged: (v) => setState(() => _to = v),
                      ),
                    ),
                  ],
                ),
                if (customRangeInvalid)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _from.isNotEmpty && _to.isNotEmpty
                          ? 'The end date must not be before the start date.'
                          : 'Pick both dates to see the report.',
                      style: TextStyle(color: hz.red, fontSize: 12.5),
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              StatGrid(
                children: [
                  StatTile(
                    icon: Icons.event_available_rounded,
                    label: 'Total Bookings',
                    value: '${active.length}',
                    color: hz.blue,
                  ),
                  StatTile(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Revenue',
                    value: inr(revenue),
                    color: hz.yellow,
                  ),
                  StatTile(
                    icon: Icons.donut_large_rounded,
                    label: 'Occupancy',
                    value: '${occupancy.round()}%',
                    color: hz.purple,
                  ),
                  StatTile(
                    icon: Icons.schedule_rounded,
                    label: 'Peak Hour',
                    value: peak == null
                        ? '—'
                        : t12('${peak.toString().padLeft(2, '0')}:00'),
                    color: hz.red,
                  ),
                  StatTile(
                    icon: Icons.payments_rounded,
                    label: 'Expenses',
                    value: inr(expenseTotal),
                    color: hz.red,
                  ),
                  StatTile(
                    icon: Icons.trending_up_rounded,
                    label: 'Net Profit',
                    value: inr(revenue - expenseTotal),
                    color: hz.green,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              HzCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('💰 Revenue Trend'),
                    const SizedBox(height: 12),
                    if (span == null || active.isEmpty)
                      SizedBox(
                        height: 120,
                        child: Center(
                          child: Text(
                            'No data for this period',
                            style: TextStyle(color: hz.tx3),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: _RevenueChart(bookings: active, range: span),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HzCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('⏱ Peak Hours'),
                    const SizedBox(height: 8),
                    _PeakHours(bookings: active),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HzCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('📊 Booking Status'),
                    const SizedBox(height: 8),
                    if (inPeriod.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            'No bookings',
                            style: TextStyle(color: hz.tx3),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          SizedBox(
                            width: 130,
                            height: 130,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 28,
                                sections: [
                                  for (final e in statusCounts.entries)
                                    if (e.value > 0)
                                      PieChartSectionData(
                                        value: e.value.toDouble(),
                                        color: hz.statusColors(e.key).$1,
                                        radius: 38,
                                        title: '${e.value}',
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                for (final e in statusCounts.entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: hz.statusColors(e.key).$1,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(e.key.label)),
                                        Text(
                                          '${e.value}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
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
                    const SectionHeader('👥 Customer Statistics'),
                    const SizedBox(height: 8),
                    InfoRow(
                      icon: Icons.people_alt_rounded,
                      label: 'Total customers',
                      value: '${customers.length}',
                    ),
                    InfoRow(
                      icon: Icons.person_pin_circle_rounded,
                      label: 'Booked in period',
                      value: '${totals.length}',
                    ),
                    InfoRow(
                      icon: Icons.repeat_rounded,
                      label: 'Repeat customers (2+)',
                      value: '$repeat',
                    ),
                    if (topCustomers.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        'Top customers by revenue',
                        style: TextStyle(
                          color: hz.tx2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final (i, e) in topCustomers.indexed)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: AvatarCircle(
                            name: e.value.name,
                            seed: e.key,
                            size: 34,
                          ),
                          title: Text(
                            '${i + 1}. ${e.value.name}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('${e.value.bookings} bookings'),
                          trailing: Text(
                            inr(e.value.revenue),
                            style: TextStyle(
                              color: hz.blue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HzCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      'Booking List',
                      trailing: TextButton.icon(
                        onPressed: _exporting ? null : () => _export(inPeriod),
                        icon: _exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('Export CSV'),
                      ),
                    ),
                    if (listForTable.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No bookings found',
                            style: TextStyle(color: hz.tx3),
                          ),
                        ),
                      )
                    else
                      for (final b in listForTable)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            b.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${fmtDate(b.date)} · ${t12(b.startTime)} – ${t12(b.endTime)}${boxCount > 1 ? ' · ${boxName(b.boxId)}' : ''}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                inr(b.amount),
                                style: TextStyle(
                                  color: hz.blue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              StatusBadge(b.status),
                            ],
                          ),
                        ),
                    if (active.length > 20)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Showing the latest 20 of ${active.length}. Export CSV for the full list.',
                          style: TextStyle(color: hz.tx3, fontSize: 12.5),
                        ),
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
}

/// Daily bars for up to ~2 months, monthly bars beyond that.
class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.bookings, required this.range});

  final List<Booking> bookings;
  final DateRange range;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final monthly = range.days > 62;
    final labels = <String>[];
    final values = <double>[];

    if (monthly) {
      final byMonth = <String, double>{};
      for (final p in Analytics.dailyRevenue(bookings, range)) {
        final key = p.date.substring(0, 7);
        byMonth[key] = (byMonth[key] ?? 0) + p.value;
      }
      for (final e in byMonth.entries) {
        final m = int.parse(e.key.substring(5, 7));
        labels.add(
          "${kMonthNames[m - 1].substring(0, 3)} '${e.key.substring(2, 4)}",
        );
        values.add(e.value);
      }
    } else {
      for (final p in Analytics.dailyRevenue(bookings, range)) {
        labels.add(p.date.substring(8));
        values.add(p.value);
      }
    }

    final maxY = values.fold(0.0, (m, v) => v > m ? v : m);
    final step = (labels.length / 7).ceil().clamp(1, 1000);
    final barWidth = labels.length > 31
        ? 4.0
        : labels.length > 14
        ? 7.0
        : 14.0;

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.15,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length || i % step != 0) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    labels[i],
                    style: TextStyle(color: hz.tx3, fontSize: 10.5),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: hz.blue,
                  width: barWidth,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PeakHours extends StatelessWidget {
  const _PeakHours({required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final hourCounts = Analytics.startHourCounts(bookings);
    // Two-hour windows that have at least one booking, in clock order.
    final windows = <int, int>{};
    for (var h = 0; h < 24; h += 2) {
      final c = (hourCounts[h] ?? 0) + (hourCounts[h + 1] ?? 0);
      if (c > 0) windows[h] = c;
    }
    if (windows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text('No bookings', style: TextStyle(color: hz.tx3)),
        ),
      );
    }
    final maxC = windows.values.reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final e in windows.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    Analytics.hourWindowLabel(e.key),
                    style: TextStyle(color: hz.tx2, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: e.value / maxC,
                      minHeight: 10,
                      backgroundColor: hz.blueLight,
                      color: e.value == maxC ? hz.red : hz.blue,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${e.value}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
