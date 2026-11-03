import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/errors.dart';
import '../../models/box.dart';
import '../../providers/app_controller.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common.dart';

/// Box management: rename boxes and enable / disable each one. Disabled boxes
/// disappear from booking forms and the calendar; their bookings are kept.
class BoxesScreen extends ConsumerWidget {
  const BoxesScreen({super.key});

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  Future<String?> _askName(
    BuildContext context, {
    String initial = '',
    required String title,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Box name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxes = ref.watch(boxesProvider);
    final hz = context.hz;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Boxes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await _askName(context, title: 'Add box');
          if (name == null || !context.mounted) return;
          await _guard(context, () async {
            await ref.read(appControllerProvider).addBox(name);
            if (context.mounted) showToast(context, 'Box added');
          });
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Box'),
      ),
      body: AsyncBody<List<CricketBox>>(
        value: boxes,
        onRetry: () =>
            ref.read(boxesProvider.notifier).refresh().catchError((_) {}),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.read(boxesProvider.notifier).refresh(),
          child: ListView(
            padding: kPagePadding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                'Disabled boxes are hidden from booking forms and the calendar. Existing bookings are kept.',
                style: TextStyle(color: hz.tx2),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const SizedBox(
                  height: 240,
                  child: EmptyState(
                    icon: Icons.sports_cricket_rounded,
                    message: 'No boxes yet. Add one to start taking bookings.',
                  ),
                )
              else
                for (final box in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HzCard(
                      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_cricket_rounded,
                            color: box.active ? hz.blue : hz.tx3,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  box.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  box.active ? 'Active' : 'Disabled',
                                  style: TextStyle(
                                    color: box.active ? hz.green : hz.tx3,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () async {
                              final name = await _askName(
                                context,
                                initial: box.name,
                                title: 'Rename box',
                              );
                              if (name == null || !context.mounted) return;
                              await _guard(
                                context,
                                () => ref
                                    .read(appControllerProvider)
                                    .renameBox(box.id, name),
                              );
                            },
                          ),
                          Switch(
                            value: box.active,
                            onChanged: (v) => _guard(
                              context,
                              () => ref
                                  .read(appControllerProvider)
                                  .setBoxActive(box.id, v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
