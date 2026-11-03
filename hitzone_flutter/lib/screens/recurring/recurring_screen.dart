import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/formatters.dart';
import '../../models/recurring_group.dart';
import '../../providers/app_controller.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecurringGroup group,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete recurring booking?',
      message:
          'This removes the group and all ${group.bookingCount} bookings it created for ${group.name}.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(appControllerProvider).deleteRecurring(group);
      if (context.mounted) showToast(context, 'Recurring deleted');
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(recurringProvider);
    final showBox = ref.watch(activeBoxesProvider).length > 1;
    final hz = context.hz;

    return AsyncBody<List<RecurringGroup>>(
      value: groups,
      onRetry: () =>
          ref.read(recurringProvider.notifier).refresh().catchError((_) {}),
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.read(recurringProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: kPagePadding,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hz.blueLight,
                border: Border.all(color: hz.blue, width: 1.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ℹ️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: hz.blueDark,
                          height: 1.5,
                          fontSize: 13,
                        ),
                        children: const [
                          TextSpan(
                            text: 'How Recurring Bookings Work\n',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: 'Pick a customer, time slot, the weekdays and the number of weeks. All bookings are created instantly. Example: ',
                          ),
                          TextSpan(
                            text: 'Mon + Wed',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' for '),
                          TextSpan(
                            text: '4 weeks',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' → 8 bookings.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              SizedBox(
                height: 280,
                child: EmptyState(
                  icon: Icons.repeat_rounded,
                  message: 'No recurring bookings yet.',
                  actionLabel: 'Create Recurring',
                  onAction: () => Routes.recurringForm(context),
                ),
              )
            else
              for (final g in list) ...[
                _RecurringCard(
                  group: g,
                  showBox: showBox,
                  onEdit: () => Routes.recurringForm(context, edit: g),
                  onDelete: () => _delete(context, ref, g),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.group,
    required this.showBox,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringGroup group;
  final bool showBox;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final created = group.createdAt == null
        ? '—'
        : fmtDate(dateKey(group.createdAt!));
    return HzCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCircle(name: group.name, seed: group.id),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '📱 ${group.phone.isEmpty ? '—' : group.phone}',
                      style: TextStyle(color: hz.tx2, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: hz.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${group.bookingCount} bookings',
                  style: TextStyle(
                    color: hz.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in group.dayLabels)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: hz.blueLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    d,
                    style: TextStyle(
                      color: hz.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _meta(
                context,
                Icons.schedule_rounded,
                '${t12(group.startTime)} – ${t12(group.endTime)}',
              ),
              _meta(context, Icons.date_range_rounded, '${group.weeks} weeks'),
              _meta(
                context,
                Icons.currency_rupee_rounded,
                '${inr(group.ratePerHour)}/h',
              ),
              if (showBox)
                _meta(context, Icons.sports_cricket_rounded, group.boxName),
              _meta(context, Icons.history_rounded, 'Created $created'),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: hz.red),
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.hz.tx3),
      const SizedBox(width: 5),
      Text(
        text,
        style: TextStyle(
          color: context.hz.tx2,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
