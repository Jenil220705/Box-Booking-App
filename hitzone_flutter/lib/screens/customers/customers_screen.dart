import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/message_templates.dart';
import '../../models/booking.dart';
import '../../models/customer.dart';
import '../../providers/app_controller.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/message_actions.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(Customer c) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete customer?',
      message: c.name,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(appControllerProvider).deleteCustomer(c);
      if (mounted) showToast(context, 'Deleted ✅');
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersWithStatsProvider);
    final q = _search.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search name or phone…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
        ),
        Expanded(
          child: AsyncBody<List<Customer>>(
            value: customers,
            onRetry: () => ref
                .read(customersProvider.notifier)
                .refresh()
                .catchError((_) {}),
            data: (all) {
              final list =
                  all
                      .where(
                        (c) =>
                            c.name.toLowerCase().contains(q) ||
                            c.phone.contains(q),
                      )
                      .toList()
                    ..sort((a, b) => b.cnt.compareTo(a.cnt));
              return RefreshIndicator(
                onRefresh: () => Future.wait([
                  ref.read(customersProvider.notifier).refresh(),
                  ref.read(bookingsProvider.notifier).refresh(),
                ]),
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 320,
                            child: EmptyState(
                              icon: Icons.people_outline_rounded,
                              message: all.isEmpty
                                  ? 'No customers yet'
                                  : 'No customers found',
                              actionLabel: all.isEmpty ? 'Add Customer' : null,
                              onAction: () => Routes.customerForm(context),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: kPagePadding,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _CustomerCard(
                          customer: list[i],
                          onTap: () => showCustomerProfile(context, list[i].id),
                          onEdit: () =>
                              Routes.customerForm(context, edit: list[i]),
                          onDelete: () => _delete(list[i]),
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hz = context.hz;
    Widget stat(String value, String label, {Color? color}) => Expanded(
      child: Column(
        children: [
          Text(value, style: AppTheme.heading(context, size: 17, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: hz.tx3, fontSize: 11.5)),
        ],
      ),
    );

    return HzCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCircle(name: customer.name, seed: customer.id, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (customer.isVip) ...[
                          const SizedBox(width: 6),
                          const Text('👑', style: TextStyle(fontSize: 14)),
                        ],
                      ],
                    ),
                    Text(
                      '📱 ${customer.phone}',
                      style: TextStyle(color: hz.tx2, fontSize: 13),
                    ),
                    if (customer.notes.isNotEmpty)
                      Text(
                        '📝 ${customer.notes}',
                        style: TextStyle(color: hz.tx3, fontSize: 12.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                stat('${customer.cnt}', 'Lifetime', color: hz.blue),
                stat('${customer.activeCount}', 'Active', color: hz.green),
                stat(customer.last, 'Last Visit'),
              ],
            ),
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'WhatsApp',
                icon: Icon(Icons.chat_rounded, color: hz.green),
                onPressed: () => MessageActions.whatsApp(
                  context,
                  ref,
                  customer.phone,
                  MessageTemplates.customerGreeting(customer.name),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_rounded),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete_rounded, color: hz.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Profile with lifetime stats and booking history.
Future<void> showCustomerProfile(BuildContext context, String customerId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) =>
          _CustomerProfile(customerId: customerId, controller: scroll),
    ),
  );
}

class _CustomerProfile extends ConsumerWidget {
  const _CustomerProfile({required this.customerId, required this.controller});

  final String customerId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hz = context.hz;
    final customer = ref
        .watch(customersWithStatsProvider)
        .value
        ?.where((c) => c.id == customerId)
        .firstOrNull;
    if (customer == null) {
      return const EmptyState(
        icon: Icons.person_off_rounded,
        message: 'Customer not found',
      );
    }

    final bookings =
        (ref.watch(bookingsProvider).value ?? const <Booking>[])
            .where((b) => b.phone == customer.phone)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final boxName = ref.watch(boxNameResolverProvider);

    final revenue = bookings
        .where((b) => !b.isCancelled)
        .fold(0.0, (s, b) => s + b.amount);
    final hours = bookings
        .where((b) => !b.isCancelled)
        .fold(0.0, (s, b) => s + (b.endMinutes - b.startMinutes) / 60);
    final boxCount = <String, int>{};
    for (final b in bookings) {
      boxCount[b.boxId] = (boxCount[b.boxId] ?? 0) + 1;
    }
    final favourite = boxCount.isEmpty
        ? null
        : (boxCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            AvatarCircle(name: customer.name, seed: customer.id, size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${customer.name}${customer.isVip ? '  👑 VIP' : ''}',
                    style: AppTheme.heading(context, size: 19),
                  ),
                  Text('📱 ${customer.phone}', style: TextStyle(color: hz.tx2)),
                ],
              ),
            ),
          ],
        ),
        if (customer.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '📝 ${customer.notes}',
              style: TextStyle(color: hz.tx2),
            ),
          ),
        const SizedBox(height: 12),
        InfoRow(
          icon: Icons.sports_cricket_rounded,
          label: 'Lifetime bookings',
          value: '${customer.cnt}',
        ),
        InfoRow(
          icon: Icons.check_circle_rounded,
          label: 'Active bookings',
          value: '${customer.activeCount}',
        ),
        InfoRow(
          icon: Icons.payments_rounded,
          label: 'Revenue',
          value: inr(revenue),
        ),
        InfoRow(
          icon: Icons.timer_rounded,
          label: 'Total hours',
          value: hours.toStringAsFixed(hours == hours.roundToDouble() ? 0 : 1),
        ),
        InfoRow(
          icon: Icons.emoji_events_rounded,
          label: 'Favourite box',
          value: favourite == null ? '-' : boxName(favourite),
        ),
        const Divider(height: 28),
        Text('Booking History', style: AppTheme.heading(context, size: 16)),
        const SizedBox(height: 6),
        if (bookings.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('No bookings yet', style: TextStyle(color: hz.tx3)),
            ),
          )
        else
          for (final b in bookings)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                fmtDate(b.date),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${boxName(b.boxId)} • ${t12(b.startTime)} - ${t12(b.endTime)}',
              ),
              trailing: StatusBadge(b.status),
            ),
      ],
    );
  }
}
