import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/analytics.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/expense_filter.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/app_controller.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _scroll = ScrollController();
  String _category = AppConfig.expenseCategories.first;
  String? _editingId;
  bool _saving = false;

  ExpenseDateFilter _dateFilter = ExpenseDateFilter.all;
  String _from = '';
  String _to = '';
  String? _categoryFilter;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _resetForm() {
    _title.clear();
    _amount.clear();
    _note.clear();
    _category = AppConfig.expenseCategories.first;
    _editingId = null;
  }

  void _startEdit(Expense e) {
    setState(() {
      _editingId = e.id;
      _title.text = e.title;
      _amount.text = formatAmount(e.amount);
      _note.text = e.note;
      _category = AppConfig.expenseCategories.contains(e.category)
          ? e.category
          : 'Other';
    });
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final controller = ref.read(appControllerProvider);
      if (_editingId != null) {
        await controller.updateExpense(
          _editingId!,
          title: _title.text,
          amount: _amount.text,
          category: _category,
          note: _note.text,
        );
      } else {
        await controller.addExpense(
          title: _title.text,
          amount: _amount.text,
          category: _category,
          note: _note.text,
        );
      }
      if (!mounted) return;
      showToast(
        context,
        _editingId != null ? 'Expense updated ✅' : 'Expense added ✅',
      );
      setState(_resetForm);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Expense e) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete expense?',
      message: 'Are you sure you want to delete "${e.title}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(appControllerProvider).deleteExpense(e);
      if (!mounted) return;
      if (_editingId == e.id) setState(_resetForm);
      showToast(context, 'Deleted ✅');
    } catch (err) {
      if (mounted) showToast(context, errorMessage(err), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hz = context.hz;
    final expensesAsync = ref.watch(expensesProvider);

    return AsyncBody<List<Expense>>(
      value: expensesAsync,
      onRetry: () =>
          ref.read(expensesProvider.notifier).refresh().catchError((_) {}),
      data: (all) {
        final now = DateTime.now();
        final total = Analytics.totalExpenses(all);
        final monthTotal = Analytics.totalExpenses(
          Analytics.expensesInRange(all, DateRange.month(now)),
        );
        final filtered = filterExpenses(
          all,
          dateFilter: _dateFilter,
          now: now,
          from: _from,
          to: _to,
          category: _categoryFilter,
        ).reversed.toList();
        final byCategory = Analytics.expensesByCategory(all);
        final top = topCategory(all);

        return RefreshIndicator(
          onRefresh: () => ref.read(expensesProvider.notifier).refresh(),
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: kPagePadding,
            children: [
              HzCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Expenses', style: TextStyle(color: hz.tx2)),
                    const SizedBox(height: 4),
                    Text(
                      inr(total),
                      style: AppTheme.heading(context, size: 30),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HzCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _editingId != null ? 'Edit Expense' : 'Add Expense',
                        style: AppTheme.heading(context, size: 17),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Expense Name *',
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Enter an expense name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null) return 'Enter an amount';
                          return n <= 0
                              ? 'Amount must be greater than zero'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        key: ValueKey('cat-$_category-$_editingId'),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: [
                          for (final c in AppConfig.expenseCategories)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) =>
                            setState(() => _category = v ?? _category),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _note,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (_editingId != null) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => setState(_resetForm),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
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
                                  : Icon(
                                      _editingId != null
                                          ? Icons.save_rounded
                                          : Icons.add_rounded,
                                    ),
                              label: Text(
                                _editingId != null
                                    ? 'Update Expense'
                                    : 'Add Expense',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StatGrid(
                children: [
                  StatTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Total Entries',
                    value: '${all.length}',
                    color: hz.blue,
                  ),
                  StatTile(
                    icon: Icons.stadium_rounded,
                    label: 'Ground',
                    value: inr(byCategory['Ground'] ?? 0),
                    color: hz.green,
                  ),
                  StatTile(
                    icon: Icons.badge_rounded,
                    label: 'Salary',
                    value: inr(byCategory['Salary'] ?? 0),
                    color: hz.purple,
                  ),
                  StatTile(
                    icon: Icons.bolt_rounded,
                    label: 'Electricity',
                    value: inr(byCategory['Electricity'] ?? 0),
                    color: hz.yellow,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              HzCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Filters', style: AppTheme.heading(context, size: 17)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ExpenseDateFilter>(
                      initialValue: _dateFilter,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.event_rounded),
                      ),
                      items: [
                        for (final f in ExpenseDateFilter.values)
                          DropdownMenuItem(value: f, child: Text(f.label)),
                      ],
                      onChanged: (v) =>
                          setState(() => _dateFilter = v ?? _dateFilter),
                    ),
                    if (_dateFilter == ExpenseDateFilter.custom) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DateField(
                              label: 'From',
                              value: _from,
                              onChanged: (v) => setState(() => _from = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DateField(
                              label: 'To',
                              value: _to,
                              onChanged: (v) => setState(() => _to = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _categoryFilter,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        for (final c in AppConfig.expenseCategories)
                          DropdownMenuItem<String?>(value: c, child: Text(c)),
                      ],
                      onChanged: (v) => setState(() => _categoryFilter = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              HzCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Summary',
                      style: AppTheme.heading(context, size: 17),
                    ),
                    const SizedBox(height: 8),
                    if (byCategory.isEmpty)
                      Text('No data', style: TextStyle(color: hz.tx3))
                    else
                      for (final cat in AppConfig.expenseCategories)
                        if ((byCategory[cat] ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat),
                                Text(
                                  inr(byCategory[cat]!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: HzCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Category',
                            style: TextStyle(color: hz.tx2, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            top ?? 'No Data',
                            style: AppTheme.heading(context, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HzCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Month',
                            style: TextStyle(color: hz.tx2, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inr(monthTotal),
                            style: AppTheme.heading(context, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Expense List (${filtered.length})',
                style: AppTheme.heading(context, size: 17),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No expenses found',
                      style: TextStyle(color: hz.tx3),
                    ),
                  ),
                )
              else
                for (final e in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HzCard(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  inr(e.amount),
                                  style: TextStyle(
                                    color: hz.blue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '📂 ${e.category}',
                                  style: TextStyle(color: hz.tx2, fontSize: 13),
                                ),
                                if (e.note.isNotEmpty)
                                  Text(
                                    '📝 ${e.note}',
                                    style: TextStyle(
                                      color: hz.tx2,
                                      fontSize: 13,
                                    ),
                                  ),
                                Text(
                                  fmtDate(e.expenseDate),
                                  style: TextStyle(
                                    color: hz.tx3,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () => _startEdit(e),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: Icon(Icons.delete_rounded, color: hz.red),
                            onPressed: () => _delete(e),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
