import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static (IconData, Color) _style(NotificationType type, HzColors hz) =>
      switch (type) {
        NotificationType.booking => (Icons.event_available_rounded, hz.blue),
        NotificationType.reminder => (Icons.alarm_rounded, hz.yellow),
        NotificationType.conflict => (Icons.warning_amber_rounded, hz.red),
        NotificationType.info => (Icons.info_rounded, hz.blueMid),
        NotificationType.success => (Icons.check_circle_rounded, hz.green),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hz = context.hz;
    final list = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final unread = list.where((n) => !n.read).length;

    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_rounded,
        message: 'No notifications yet.\nBookings, reminders and conflicts will show up here.',
      );
    }

    return ListView(
      padding: kPagePadding,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$unread unread',
                style: TextStyle(color: hz.tx2, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: unread == 0
                  ? null
                  : () {
                      notifier.markAllRead();
                      showToast(context, 'All read ✅');
                    },
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark All Read'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final n in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HzCard(
              onTap: () => notifier.markRead(n.id),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _style(n.type, hz).$2.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _style(n.type, hz).$1,
                      color: _style(n.type, hz).$2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          n.message,
                          style: TextStyle(color: hz.tx2, fontSize: 13.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo(n.createdAt),
                          style: TextStyle(color: hz.tx3, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (!n.read)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: hz.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
