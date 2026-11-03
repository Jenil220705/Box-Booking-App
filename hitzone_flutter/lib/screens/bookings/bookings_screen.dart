import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/booking.dart';
import '../../providers/data_providers.dart';
import '../../widgets/booking_widgets.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  final _search = TextEditingController();
  BookingStatus? _status; // null = all
  String _date = '';
  String? _boxId; // null = all boxes

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Booking> _filtered(List<Booking> all) {
    final q = _search.text.trim().toLowerCase();
    final list = all.where((b) {
      if (_status != null && b.status != _status) return false;
      if (_date.isNotEmpty && b.date != _date) return false;
      if (_boxId != null && b.boxId != _boxId) return false;
      if (q.isNotEmpty &&
          !b.name.toLowerCase().contains(q) &&
          !b.phone.contains(q)) {
        return false;
      }
      return true;
    }).toList();
    // Newest date first, earliest start first within a day (as the web app).
    list.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(bookingsProvider);
    final boxes = ref.watch(activeBoxesProvider);
    final hz = context.hz;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search name or phone…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip(
                      'All',
                      _status == null,
                      () => setState(() => _status = null),
                    ),
                    for (final s in BookingStatus.values)
                      _chip(
                        s.label,
                        _status == s,
                        () => setState(() => _status = s),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DateField(
                      label: 'Filter by date',
                      value: _date,
                      onChanged: (v) => setState(() => _date = v),
                      onClear: () => setState(() => _date = ''),
                    ),
                  ),
                  if (boxes.length > 1) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _boxId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Box'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All boxes'),
                          ),
                          for (final b in boxes)
                            DropdownMenuItem<String?>(
                              value: b.id,
                              child: Text(
                                b.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _boxId = v),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AsyncBody<List<Booking>>(
            value: bookings,
            onRetry: () => ref
                .read(bookingsProvider.notifier)
                .refresh()
                .catchError((_) {}),
            data: (all) {
              final list = _filtered(all);
              return RefreshIndicator(
                onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 320,
                            child: EmptyState(
                              icon: Icons.event_busy_rounded,
                              message: all.isEmpty
                                  ? 'No bookings yet'
                                  : 'No bookings found',
                              actionLabel: all.isEmpty ? 'New Booking' : null,
                              onAction: () => Routes.bookingForm(context),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: kPagePadding,
                        itemCount: list.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Text(
                              '${list.length} booking${list.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: hz.tx2,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                          return BookingCard(
                            booking: list[i - 1],
                            index: i - 1,
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? Colors.white : context.hz.tx2,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
