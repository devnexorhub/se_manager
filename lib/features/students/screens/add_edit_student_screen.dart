import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/category_providers.dart';
import '../../../providers/student_providers.dart';

/// Screen to create or edit a student/member.
class AddEditStudentScreen extends ConsumerStatefulWidget {
  const AddEditStudentScreen({
    super.key,
    this.studentId,
    required this.categoryId,
  });

  final int? studentId;
  final int categoryId;

  bool get isEditing => studentId != null;

  @override
  ConsumerState<AddEditStudentScreen> createState() =>
      _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadStudent();
    }
  }

  Future<void> _loadStudent() async {
    final student =
        await ref.read(studentRepositoryProvider).getById(widget.studentId!);
    _nameController.text = student.name;
    _contactController.text = student.contact ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(studentRepositoryProvider);
      final name = _nameController.text.trim();
      final contact = _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim();

      if (widget.isEditing) {
        final student = await repo.getById(widget.studentId!);
        await repo.update(
          id: widget.studentId!,
          name: name,
          contact: contact,
          categoryId: widget.categoryId,
          createdAt: student.createdAt,
        );
      } else {
        await repo.add(
          name: name,
          contact: contact,
          categoryId: widget.categoryId,
        );
      }

      // Refresh providers
      ref.invalidate(studentsStreamProvider);
      ref.invalidate(studentsByCategoryProvider(widget.categoryId));
      ref.invalidate(studentCountProvider);
      ref.invalidate(categoryMemberCountProvider(widget.categoryId));
      if (widget.isEditing) {
        ref.invalidate(studentByIdProvider(widget.studentId!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Member updated successfully'
                  : 'Member added successfully',
            ),
            backgroundColor: AppColors.success,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isEditing ? AppStrings.editMember : AppStrings.addMember),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Icon ─────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Name Field ──────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.memberName,
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 20),

              // ── Contact Field ───────────────────────────────────
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.contactInfo} (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: Validators.phone,
              ),
              const SizedBox(height: 36),

              // ── Save Button ─────────────────────────────────────
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving…'
                        : widget.isEditing
                            ? 'Update Member'
                            : 'Add Member',
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
