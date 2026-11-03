import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/errors.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer.dart';
import '../../providers/app_controller.dart';
import '../../widgets/common.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.edit});

  final Customer? edit;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.edit?.name ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.edit?.phone ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.edit?.notes ?? '',
  );
  bool _saving = false;

  bool get _isEdit => widget.edit != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final controller = ref.read(appControllerProvider);
      if (_isEdit) {
        await controller.updateCustomer(
          widget.edit!,
          name: _name.text,
          phone: _phone.text,
          notes: _notes.text,
        );
      } else {
        await controller.addCustomer(
          name: _name.text,
          phone: _phone.text,
          notes: _notes.text,
        );
      }
      if (!mounted) return;
      showToast(context, _isEdit ? 'Updated ✅' : 'Added ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Customer' : 'Add Customer')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Customer name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter the customer name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile *',
                  hintText: '9876543210',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (v) => isValidPhone(v ?? '')
                    ? null
                    : 'Enter valid 10 digit mobile number',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any notes…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                      label: const Text('Save'),
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
