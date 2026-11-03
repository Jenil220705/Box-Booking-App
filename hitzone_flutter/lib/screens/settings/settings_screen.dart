import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/message_templates.dart';
import '../../providers/app_controller.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _ground;
  late final TextEditingController _address;
  late final TextEditingController _contact;
  late final TextEditingController _wa;
  late final TextEditingController _recurWa;
  late final TextEditingController _sms;
  final _password = TextEditingController();
  late String _opens;
  late String _closes;
  int? _boxCount; // null until the user edits it; mirrors the active box count
  bool _busyBoxes = false;
  bool _busyPassword = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _ground = TextEditingController(text: s.groundName);
    _address = TextEditingController(text: s.address);
    _contact = TextEditingController(text: s.contact);
    _wa = TextEditingController(text: s.waTemplate);
    _recurWa = TextEditingController(text: s.recurringWaTemplate);
    _sms = TextEditingController(text: s.smsTemplate);
    _opens = s.opens;
    _closes = s.closes;
  }

  @override
  void dispose() {
    for (final c in [
      _ground,
      _address,
      _contact,
      _wa,
      _recurWa,
      _sms,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveGround() async {
    await ref
        .read(settingsProvider.notifier)
        .saveGround(
          name: _ground.text.trim(),
          address: _address.text.trim(),
          contact: _contact.text.trim(),
          opens: _opens,
          closes: _closes,
        );
    if (mounted) showToast(context, 'Ground details saved ✅');
  }

  Future<void> _updateBoxes(int current) async {
    final target = _boxCount ?? current;
    setState(() => _busyBoxes = true);
    try {
      final message = await ref
          .read(appControllerProvider)
          .setActiveBoxCount(target);
      if (mounted) {
        setState(() => _boxCount = null);
        showToast(context, message);
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busyBoxes = false);
    }
  }

  Future<void> _updatePassword() async {
    setState(() => _busyPassword = true);
    try {
      await ref.read(authServiceProvider).updatePassword(_password.text);
      if (mounted) {
        _password.clear();
        showToast(context, 'Password Updated ✅');
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busyPassword = false);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again.',
      confirmLabel: 'Log out',
    );
    if (!ok) return;
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final boxes = ref.watch(boxesProvider);
    final activeCount = boxes.value?.where((b) => b.active).length ?? 0;
    final count = _boxCount ?? activeCount;
    final email = ref.watch(authServiceProvider).currentUser?.email ?? '';

    return ListView(
      padding: kPagePadding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _Section(
          title: '🏟️ Ground',
          children: [
            TextField(
              controller: _ground,
              decoration: const InputDecoration(labelText: 'Ground Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TimeField(
                    label: 'Opens',
                    value: _opens,
                    onChanged: (v) => setState(() => _opens = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TimeField(
                    label: 'Closes',
                    value: _closes,
                    onChanged: (v) => setState(() => _closes = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _saveGround,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Ground Details'),
              ),
            ),
            const Divider(height: 32),
            Text(
              'Number Of Boxes',
              style: TextStyle(color: hz.tx2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (boxes.hasError && !boxes.hasValue)
              Text(
                'Could not load boxes: ${errorMessage(boxes.error!)}',
                style: TextStyle(color: hz.red),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.outlined(
                        tooltip: 'Fewer boxes',
                        onPressed: count > 1
                            ? () => setState(() => _boxCount = count - 1)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          '$count',
                          style: AppTheme.heading(context, size: 22),
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'More boxes',
                        onPressed: () => setState(() => _boxCount = count + 1),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _busyBoxes || count == activeCount
                        ? null
                        : () => _updateBoxes(activeCount),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    icon: _busyBoxes
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sports_cricket_rounded),
                    label: const Text('Update Boxes'),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_rounded),
              title: const Text(
                'Manage boxes',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Rename boxes, enable or disable each one'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Routes.boxes(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Section(
          title: '⚙️ Preferences',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: settings.darkMode,
              onChanged: notifier.setDarkMode,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'WhatsApp / SMS Alerts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Offer the confirmation message after saving a booking',
              ),
              value: settings.whatsappAlerts,
              onChanged: notifier.setWhatsappAlerts,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Conflict Detection',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Block double booking of a box'),
              value: settings.conflictDetection,
              onChanged: notifier.setConflictDetection,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TemplateSection(
          title: '💬 WhatsApp Message Template',
          description:
              'Customize the booking confirmation message sent via WhatsApp.',
          variables: MessageTemplates.bookingVariables,
          controller: _wa,
          defaultText: MessageTemplates.defaultWhatsApp,
          rows: 8,
          saveLabel: 'Save WhatsApp Template',
          onSave: () async {
            await notifier.saveWaTemplate(_wa.text);
            if (context.mounted) {
              showToast(context, 'WhatsApp template saved 💬');
            }
          },
        ),
        const SizedBox(height: 14),
        _TemplateSection(
          title: '🔁 Recurring WhatsApp Template',
          description: 'Message offered after a recurring booking is created.',
          variables: MessageTemplates.recurringVariables,
          controller: _recurWa,
          defaultText: MessageTemplates.defaultRecurringWhatsApp,
          rows: 8,
          saveLabel: 'Save Recurring Template',
          onSave: () async {
            await notifier.saveRecurringTemplate(_recurWa.text);
            if (context.mounted) {
              showToast(context, 'Recurring WhatsApp template saved 💬');
            }
          },
        ),
        const SizedBox(height: 14),
        _TemplateSection(
          title: '📱 SMS Message Template',
          description: 'Customize the SMS offered after a booking. Keep it short (160 chars ideal).',
          variables: MessageTemplates.bookingVariables,
          controller: _sms,
          defaultText: MessageTemplates.defaultSms,
          rows: 4,
          saveLabel: 'Save SMS Template',
          onSave: () async {
            await notifier.saveSmsTemplate(_sms.text);
            if (context.mounted) showToast(context, 'SMS template saved 📱');
          },
        ),
        const SizedBox(height: 14),
        _Section(
          title: '🔐 Admin Account',
          children: [
            InfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'Signed in as',
              value: email.isEmpty ? '—' : email,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'At least 6 characters',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busyPassword ? null : _updatePassword,
                    icon: _busyPassword
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.key_rounded),
                    label: const Text('Update Password'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return HzCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTheme.heading(context, size: 17)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _TemplateSection extends StatelessWidget {
  const _TemplateSection({
    required this.title,
    required this.description,
    required this.variables,
    required this.controller,
    required this.defaultText,
    required this.rows,
    required this.saveLabel,
    required this.onSave,
  });

  final String title;
  final String description;
  final List<String> variables;
  final TextEditingController controller;
  final String defaultText;
  final int rows;
  final String saveLabel;
  final Future<void> Function() onSave;

  void _insert(String variable) {
    final text = controller.text;
    final sel = controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final token = '{$variable}';
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    return _Section(
      title: title,
      children: [
        Text(description, style: TextStyle(color: hz.tx2, fontSize: 13)),
        const SizedBox(height: 8),
        Text(
          'Tap a variable to insert it:',
          style: TextStyle(color: hz.tx3, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final v in variables)
              ActionChip(
                label: Text(
                  '{$v}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () => _insert(v),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          minLines: rows,
          maxLines: rows + 6,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(alignLabelWithHint: true),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded),
                label: Text(saveLabel, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => controller.text = defaultText,
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}
