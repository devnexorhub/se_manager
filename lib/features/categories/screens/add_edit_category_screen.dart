import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/category_providers.dart';
import 'category_list_screen.dart' show getCategoryIcon;

/// Available icon choices for categories.
const _iconChoices = <String>[
  'folder',
  'school',
  'business',
  'home',
  'group',
  'sports',
  'restaurant',
  'shopping',
  'travel',
  'health',
  'music',
  'code',
  'star',
  'pets',
  'church',
  'volunteer',
];

/// Available color choices for categories.
const _colorChoices = <int>[
  0xFF6C5CE7, // purple
  0xFF00CEC9, // teal
  0xFF00B894, // green
  0xFFFDAA5E, // amber
  0xFFFF6B6B, // red
  0xFF74B9FF, // blue
  0xFFE17055, // deep orange
  0xFFD63031, // crimson
  0xFF0984E3, // royal blue
  0xFF6AB04C, // olive
  0xFFEB4D4B, // watermelon
  0xFFF9CA24, // gold
];

/// Screen to create or edit a category.
class AddEditCategoryScreen extends ConsumerStatefulWidget {
  const AddEditCategoryScreen({super.key, this.categoryId});

  final int? categoryId;

  bool get isEditing => categoryId != null;

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState
    extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIcon = 'folder';
  int _selectedColor = 0xFF6C5CE7;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadCategory();
    }
  }

  Future<void> _loadCategory() async {
    final category =
        await ref.read(categoryRepositoryProvider).getById(widget.categoryId!);
    _nameController.text = category.name;
    _descriptionController.text = category.description ?? '';
    setState(() {
      _selectedIcon = category.icon;
      _selectedColor = category.color;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(categoryRepositoryProvider);
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      if (widget.isEditing) {
        final category = await repo.getById(widget.categoryId!);
        await repo.update(
          id: widget.categoryId!,
          name: name,
          description: description,
          icon: _selectedIcon,
          color: _selectedColor,
          createdAt: category.createdAt,
        );
      } else {
        await repo.add(
          name: name,
          description: description,
          icon: _selectedIcon,
          color: _selectedColor,
        );
      }

      // Refresh category list
      ref.invalidate(categoriesStreamProvider);
      ref.invalidate(categoryCountProvider);
      if (widget.isEditing) {
        ref.invalidate(categoryByIdProvider(widget.categoryId!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Category updated successfully'
                  : 'Category created successfully',
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
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = Color(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? AppStrings.editCategory
            : AppStrings.addCategory),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Preview Icon ──────────────────────────────────────
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: activeColor.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: activeColor.withAlpha(100),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    getCategoryIcon(_selectedIcon),
                    size: 40,
                    color: activeColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Name Field ────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.categoryName,
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Category name'),
              ),
              const SizedBox(height: 20),

              // ── Description Field ─────────────────────────────────
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '${AppStrings.description} (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 28),

              // ── Icon Picker ───────────────────────────────────────
              Text(
                'Choose Icon',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _iconChoices.map((iconName) {
                  final isSelected = _selectedIcon == iconName;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withAlpha(isDark ? 60 : 30)
                            : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.backgroundLight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? activeColor
                              : Colors.grey.withAlpha(50),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        getCategoryIcon(iconName),
                        color: isSelected
                            ? activeColor
                            : theme.iconTheme.color?.withAlpha(150),
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── Color Picker ──────────────────────────────────────
              Text(
                'Choose Color',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorChoices.map((colorVal) {
                  final c = Color(colorVal);
                  final isSelected = _selectedColor == colorVal;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = colorVal),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withAlpha(100),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 22)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // ── Save Button ───────────────────────────────────────
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
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving…'
                        : widget.isEditing
                            ? 'Update Category'
                            : 'Create Category',
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
