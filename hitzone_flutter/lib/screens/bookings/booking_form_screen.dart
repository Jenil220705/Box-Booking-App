import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../models/box.dart';
import '../../providers/app_controller.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/message_actions.dart';
import '../../widgets/pickers.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({
    super.key,
    this.edit,
    this.prefillDate,
    this.prefillFrom,
    this.prefillBoxId,
  });

  final Booking? edit;
  final String? prefillDate;
  final String? prefillFrom;
  final String? prefillBoxId;

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _name;
  late final TextEditingController _rate;
  late String _date;
  late String _from;
  late String _to;
  late BookingStatus _status;
  String? _boxId;
  bool _saving = false;
  String? _conflict;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final b = widget.edit;
    if (b != null) {
      _phone = TextEditingController(text: b.phone);
      _name = TextEditingController(text: b.name);
      final rate = b.effectiveRate;
      _rate = TextEditingController(
        text: rate == rate.roundToDouble()
            ? rate.toStringAsFixed(0)
            : rate.toStringAsFixed(2),
      );
      _date = b.date;
      _from = b.startTime;
      _to = b.endTime;
      _status = b.status;
      _boxId = b.boxId;
    } else {
      _phone = TextEditingController();
      _name = TextEditingController();
      _rate = TextEditingController(
        text: AppConfig.defaultHourlyRate.toStringAsFixed(0),
      );
      _date = widget.prefillDate ?? todayKey();
      _from = widget.prefillFrom ?? '07:00';
      _to = widget.prefillFrom != null
          ? minutesToTime(parseMinutes(widget.prefillFrom) + 60)
          : '09:00';
      _status = BookingStatus.confirmed;
      _boxId = widget.prefillBoxId;
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  double get _rateValue => double.tryParse(_rate.text.trim()) ?? 0;

  /// Boxes the user may pick: active ones, plus the booking's own box when it
  /// has since been disabled.
  List<CricketBox> _selectableBoxes() {
    final all = ref.read(boxesProvider).value ?? const <CricketBox>[];
    return all.where((b) => b.active || b.id == widget.edit?.boxId).toList();
  }

  String? _effectiveBoxId(List<CricketBox> boxes) {
    if (_boxId != null && boxes.any((b) => b.id == _boxId)) return _boxId;
    return boxes.isNotEmpty ? boxes.first.id : null;
  }

  void _autofillName(String phone) {
    final customers = ref.read(customersProvider).value;
    if (customers == null) return;
    for (final c in customers) {
      if (c.phone == phone) {
        setState(() => _name.text = c.name);
        return;
      }
    }
  }

  BookingDraft? _draft() {
    final boxes = _selectableBoxes();
    final boxId = _effectiveBoxId(boxes);
    if (boxId == null) return null;
    return BookingDraft(
      name: _name.text.trim(),
      phone: _phone.text,
      date: _date,
      startTime: _from,
      endTime: _to,
      boxId: boxId,
      ratePerHour: _rateValue,
      status: _status,
    );
  }

  Future<void> _save() async {
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
      if (_isEdit) {
        await controller.updateBooking(widget.edit!, draft);
      } else {
        await controller.createBooking(draft);
      }
      if (!mounted) return;
      showToast(context, _isEdit ? 'Booking updated ✅' : 'Booking added ✅');
      if (draft.status != BookingStatus.cancelled) {
        await MessageActions.offerConfirmation(
          context,
          ref,
          title: 'Booking saved — notify ${draft.name}?',
          phone: draft.phone,
          whatsAppText: MessageActions.bookingWhatsAppText(
            ref,
            name: draft.name,
            date: draft.date,
            from: draft.startTime,
            to: draft.endTime,
          ),
          smsText: MessageActions.bookingSmsText(
            ref,
            name: draft.name,
            date: draft.date,
            from: draft.startTime,
            to: draft.endTime,
          ),
        );
      }
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

  Future<void> _sendWhatsApp() async {
    final phone = _phone.text;
    if (!isValidPhone(phone)) {
      showToast(context, 'Enter mobile number first', error: true);
      return;
    }
    await MessageActions.whatsApp(
      context,
      ref,
      phone,
      MessageActions.bookingWhatsAppText(
        ref,
        name: _name.text.trim(),
        date: _date,
        from: _from,
        to: _to,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    // Rebuild when boxes finish loading.
    ref.watch(boxesProvider);
    final boxes = _selectableBoxes();
    final boxId = _effectiveBoxId(boxes);
    final amount = bookingAmount(_from, _to, _rateValue);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Booking' : 'New Booking')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (_conflict != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hz.red.withValues(alpha: 0.12),
                    border: Border.all(color: hz.red.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Slot Already Booked!',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: hz.red,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _conflict!,
                              style: TextStyle(color: hz.red, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  if (v.length == 10) _autofillName(v);
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
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null) return 'Enter the hourly rate';
                  if (value < 0) return 'Rate cannot be negative';
                  return null;
                },
              ),
              if (boxes.length > 1) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: boxId,
                  decoration: const InputDecoration(
                    labelText: 'Box *',
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
                  validator: (v) => v == null ? 'Select a box' : null,
                ),
              ],
              const SizedBox(height: 14),
              DateField(
                label: 'Date *',
                value: _date,
                onChanged: (v) => setState(() => _date = v),
              ),
              const SizedBox(height: 14),
              TimeRangeFields(
                from: _from,
                to: _to,
                onFromChanged: (v) => setState(() => _from = v),
                onToChanged: (v) => setState(() => _to = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<BookingStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
                items: [
                  for (final s in BookingStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hz.blueLight,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: hz.blueDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Total: ${inr(amount)}  ·  ${calcHours(_from, _to)}h × ${inr(_rateValue)}',
                        style: TextStyle(
                          color: hz.blueDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _sendWhatsApp,
                      icon: Icon(Icons.chat_rounded, color: hz.green),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
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
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(_isEdit ? 'Save Changes' : 'Book'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
