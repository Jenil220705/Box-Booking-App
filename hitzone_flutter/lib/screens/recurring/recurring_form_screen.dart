import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/formatters.dart';
import '../../models/box.dart';
import '../../models/recurring_group.dart';
import '../../providers/app_controller.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/message_actions.dart';
import '../../widgets/pickers.dart';

class RecurringFormScreen extends ConsumerStatefulWidget {
  const RecurringFormScreen({super.key, this.edit, this.prefillDate});

  final RecurringGroup? edit;
  final String? prefillDate;

  @override
  ConsumerState<RecurringFormScreen> createState() =>
      _RecurringFormScreenState();
}

class _RecurringFormScreenState extends ConsumerState<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _name;
  late final TextEditingController _rate;
  late final TextEditingController _weeks;
  late String _startDate;
  late String _from;
  late String _to;
  late List<int> _days;
  String? _boxId;
  bool _saving = false;
  String? _conflict;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final g = widget.edit;
    _phone = TextEditingController(text: g?.phone ?? '');
    _name = TextEditingController(text: g?.name ?? '');
    _rate = TextEditingController(
      text: g == null
          ? ''
          : (g.ratePerHour == g.ratePerHour.roundToDouble()
                ? g.ratePerHour.toStringAsFixed(0)
                : g.ratePerHour.toString()),
    );
    _weeks = TextEditingController(text: '${g?.weeks ?? 4}');
    _startDate = widget.prefillDate ?? todayKey();
    _from = g?.startTime ?? '19:00';
    _to = g?.endTime ?? '21:00';
    _days = g == null ? [1] : List.of(g.days); // Monday by default
    _boxId = g?.boxId;
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _rate.dispose();
    _weeks.dispose();
    super.dispose();
  }

  List<CricketBox> _selectableBoxes() {
    final all = ref.read(boxesProvider).value ?? const <CricketBox>[];
    return all.where((b) => b.active || b.id == widget.edit?.boxId).toList();
  }

  String? _effectiveBoxId(List<CricketBox> boxes) {
    if (_boxId != null && boxes.any((b) => b.id == _boxId)) return _boxId;
    return boxes.isNotEmpty ? boxes.first.id : null;
  }

  int get _weeksValue => int.tryParse(_weeks.text.trim()) ?? 0;

  RecurringDraft? _draft() {
    final boxId = _effectiveBoxId(_selectableBoxes());
    if (boxId == null) return null;
    return RecurringDraft(
      name: _name.text.trim(),
      phone: _phone.text,
      boxId: boxId,
      days: _days,
      startTime: _from,
      endTime: _to,
      weeks: _weeksValue,
      ratePerHour: double.tryParse(_rate.text.trim()) ?? 0,
      startDate: _startDate,
    );
  }

  Future<void> _save() async {
    if (_days.isEmpty) {
      showToast(context, 'Select at least one day', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final draft = _draft();
    if (draft == null) {
      showToast(
        context,
        'No active box available. Enable a box in Settings first.',
        error: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _conflict = null;
    });
    try {
      final controller = ref.read(appControllerProvider);
      final outcome = _isEdit
          ? await controller.updateRecurring(widget.edit!, draft)
          : await controller.createRecurring(draft);
      if (!mounted) return;
      showToast(
        context,
        _isEdit
            ? 'Recurring updated'
            : '${outcome.bookings.length} bookings created 🔁',
      );
      await MessageActions.offerConfirmation(
        context,
        ref,
        title: 'Recurring booking saved — notify ${draft.name}?',
        phone: draft.phone,
        whatsAppText: MessageActions.recurringWhatsAppText(
          ref,
          draft,
          outcome.bookings,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on SlotConflictException catch (e) {
      if (mounted) {
        setState(() => _conflict = e.message);
        showToast(context, '❌ ${e.message}', error: true);
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _preview(List<CricketBox> boxes, String? boxId) {
    final boxName =
        boxes.where((b) => b.id == boxId).map((b) => b.name).firstOrNull ?? '';
    final names = _days.map((d) => kDayNames[d]).join(' + ');
    final total = _days.length * _weeksValue;
    final who = _name.text.trim().isEmpty ? 'Customer' : _name.text.trim();
    return '$who${boxName.isEmpty ? '' : ' · $boxName'} · ${names.isEmpty ? 'no days' : names} · $_weeksValue weeks → $total bookings will be created';
  }

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    ref.watch(boxesProvider);
    final boxes = _selectableBoxes();
    final boxId = _effectiveBoxId(boxes);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Recurring Booking' : '🔁 Recurring Booking',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (_isEdit)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hz.yellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Text(
                    'Saving regenerates every booking of this group from the start date below. Existing bookings of the group are replaced.',
                    style: TextStyle(color: hz.tx, fontSize: 13),
                  ),
                ),
              if (_conflict != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hz.red.withValues(alpha: 0.12),
                    border: Border.all(color: hz.red.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Text(
                    '⚠️ $_conflict',
                    style: TextStyle(
                      color: hz.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: '9876543210',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                onChanged: (v) {
                  if (v.length != 10) return;
                  final match = ref
                      .read(customersProvider)
                      .value
                      ?.where((c) => c.phone == v)
                      .firstOrNull;
                  if (match != null) setState(() => _name.text = match.name);
                },
                validator: (v) => isValidPhone(v ?? '')
                    ? null
                    : 'Enter valid 10 digit mobile number',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  hintText: 'e.g. Rahul Shah',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter the customer name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount / Hour (₹) *',
                  hintText: 'Enter hourly rate',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  return value == null || value <= 0
                      ? 'Enter the hourly rate'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              DateField(
                label: 'Start Date *',
                value: _startDate,
                onChanged: (v) => setState(() => _startDate = v),
              ),
              if (boxes.length > 1) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: boxId,
                  decoration: const InputDecoration(
                    labelText: 'Ground / Box *',
                    prefixIcon: Icon(Icons.sports_cricket_rounded),
                  ),
                  items: [
                    for (final b in boxes)
                      DropdownMenuItem(
                        value: b.id,
                        child: Text(b.active ? b.name : '${b.name} (disabled)'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _boxId = v),
                ),
              ],
              const SizedBox(height: 14),
              TimeRangeFields(
                from: _from,
                to: _to,
                onFromChanged: (v) => setState(() => _from = v),
                onToChanged: (v) => setState(() => _to = v),
              ),
              const SizedBox(height: 18),
              Text(
                'Repeat on days *',
                style: TextStyle(color: hz.tx2, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 0; d < 7; d++)
                    FilterChip(
                      label: Text(kDayNames[d]),
                      selected: _days.contains(d),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _days.contains(d) ? Colors.white : hz.tx2,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (on) =>
                          setState(() => on ? _days.add(d) : _days.remove(d)),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _weeks,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Number of Weeks * (1–52)',
                  prefixIcon: Icon(Icons.date_range_rounded),
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return n == null || n < 1 || n > 52
                      ? 'Enter 1 to 52 weeks'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hz.blueLight,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Text(
                  'ℹ️ ${_preview(boxes, boxId)}',
                  style: TextStyle(
                    color: hz.blueDark,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isEdit ? Icons.save_rounded : Icons.repeat_rounded),
                label: Text(_isEdit ? 'Save Changes' : 'Create Bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
