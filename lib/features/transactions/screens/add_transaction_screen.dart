import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/student_providers.dart';
import '../../../providers/transaction_providers.dart';

/// Screen to add a new transaction (deposit or withdrawal).
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.deposit;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (mounted) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time?.hour ?? DateTime.now().hour,
            time?.minute ?? DateTime.now().minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.add(
        studentId: widget.studentId,
        type: _type.name,
        amount: double.parse(_amountController.text.trim()),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: _selectedDate,
      );

      // Refresh dependent providers
      ref.invalidate(studentTransactionsProvider(widget.studentId));
      ref.invalidate(studentBalanceProvider(widget.studentId));
      ref.invalidate(studentsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_type.label} of ${_amountController.text} added',
            ),
            backgroundColor: _type.isDeposit
                ? AppColors.deposit
                : AppColors.withdrawal,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeposit = _type.isDeposit;
    final activeColor = isDeposit ? AppColors.deposit : AppColors.withdrawal;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addTransaction)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Type Toggle ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: TransactionType.values.map((type) {
                    final selected = _type == type;
                    final color = type.isDeposit
                        ? AppColors.deposit
                        : AppColors.withdrawal;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withAlpha(30)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: color, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type.isDeposit
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: selected ? color : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: selected ? color : Colors.grey,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // ── Amount Field ────────────────────────────────────
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: AppStrings.amount,
                  prefixIcon: Icon(
                    Icons.attach_money_rounded,
                    color: activeColor,
                  ),
                  prefixText: '\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
                validator: Validators.amount,
              ),
              const SizedBox(height: 20),

              // ── Date Picker ─────────────────────────────────────
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.date,
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}  '
                    '${TimeOfDay.fromDateTime(_selectedDate).format(context)}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Note Field ──────────────────────────────────────
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.note} (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 36),

              // ── Save Button ─────────────────────────────────────
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: activeColor,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isDeposit
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving…'
                        : 'Add ${_type.label}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
