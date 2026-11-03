import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/utils/formatters.dart';

/// Read-only field that opens the native Material date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.onClear,
    this.errorText,
  });

  final String label;

  /// `yyyy-MM-dd`, empty when unset.
  final String value;
  final ValueChanged<String> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final VoidCallback? onClear;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final initial = value.isEmpty ? DateTime.now() : parseDateKey(value);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (picked != null) onChanged(dateKey(picked));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: const Icon(Icons.event_rounded),
          suffixIcon: onClear != null && value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear',
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          value.isEmpty ? 'Select date' : fmtDate(value),
          style: TextStyle(color: value.isEmpty ? context.hz.tx3 : null),
        ),
      ),
    );
  }
}

/// Read-only field that opens the native Material time picker.
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;

  /// `HH:mm`
  final String value;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final mins = parseMinutes(value);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: mins ~/ 60, minute: mins % 60),
    );
    if (picked != null) {
      onChanged(minutesToTime(picked.hour * 60 + picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule_rounded),
        ),
        child: Text(
          t12(value),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// From / To pair with the computed duration underneath.
class TimeRangeFields extends StatelessWidget {
  const TimeRangeFields({
    super.key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
  });

  final String from;
  final String to;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;

  @override
  Widget build(BuildContext context) {
    final hours = calcHours(from, to);
    final valid = parseMinutes(to) > parseMinutes(from);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TimeField(
                label: 'From',
                value: from,
                onChanged: onFromChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TimeField(label: 'To', value: to, onChanged: onToChanged),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          valid ? 'Duration: ${hours}h' : 'End time must be after start time',
          style: TextStyle(
            color: valid ? context.hz.tx2 : context.hz.red,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
