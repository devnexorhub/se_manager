import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/enums.dart';
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/student_providers.dart';
import '../../providers/transaction_providers.dart';

/// Settings screen with theme toggle, currency, export, and backup.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final currency = ref.watch(currencyProvider);


    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Appearance Section ────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          SwitchListTile.adaptive(
            secondary: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
              ),
            ),
            title: const Text(AppStrings.darkMode),
            subtitle: Text(isDark ? 'Dark theme active' : 'Light theme active'),
            value: isDark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ),

          // ── Currency Section ─────────────────────────────────────
          _SectionHeader(title: 'Preferences'),
          ListTile(
            leading: const Icon(Icons.currency_exchange_rounded),
            title: const Text(AppStrings.currency),
            subtitle: Text(currency),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showCurrencyPicker(context, ref, currency),
          ),

          // ── Export Section ───────────────────────────────────────
          _SectionHeader(title: 'Data Management'),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export to CSV'),
            subtitle: const Text('Export all transaction data'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _exportCSV(context, ref),
          ),

          // ── Backup ───────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text(AppStrings.backup),
            subtitle: const Text('Save a copy of your database'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _backup(context),
          ),

          // ── Restore ──────────────────────────────────────────────
          ListTile(
            leading: Icon(Icons.restore_rounded, color: AppColors.warning),
            title: const Text(AppStrings.restore),
            subtitle: const Text('Restore from a backup file'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _restore(context, ref),
          ),

          const Divider(height: 32),

          // ── About ────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text(AppStrings.appName),
            subtitle: const Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  // ── Currency Picker ────────────────────────────────────────────────

  void _showCurrencyPicker(
      BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Currency',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: AppCurrency.values.map((c) => ListTile(
                          leading: Text(c.symbol,
                              style: const TextStyle(fontSize: 20)),
                          title: Text(c.name),
                          subtitle: Text(c.code),
                          trailing: c.code == current
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary)
                              : null,
                          onTap: () {
                            ref.read(currencyProvider.notifier).setCurrency(c.code);
                            Navigator.pop(ctx);
                          },
                        )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Export CSV ─────────────────────────────────────────────────────

  Future<void> _exportCSV(BuildContext context, WidgetRef ref) async {
    try {
      final txRepo = ref.read(transactionRepositoryProvider);
      final studentRepo = ref.read(studentRepositoryProvider);

      final transactions = await txRepo.getAll();
      final students = await studentRepo.getAll();
      final nameMap = {for (final s in students) s.id: s.name};

      final rows = <List<String>>[
        ['ID', 'Student', 'Type', 'Amount', 'Currency', 'Note', 'Date'],
        ...transactions.map((tx) => [
              tx.id.toString(),
              nameMap[tx.studentId] ?? 'Unknown',
              tx.type,
              tx.amount.toStringAsFixed(2),
              tx.currency,
              tx.note ?? '',
              tx.createdAt.toIso8601String(),
            ]),
      ];

      final csvData = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/se_manager_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Student Expense Manager - Export',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Backup ────────────────────────────────────────────────────────

  Future<void> _backup(BuildContext context) async {
    try {
      final dbPath = await AppDatabase.databasePath;
      final srcFile = File(dbPath);

      if (!await srcFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No database found to backup'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      await Share.shareXFiles(
        [XFile(dbPath)],
        subject: 'Student Expense Manager - Backup',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup shared successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Restore ───────────────────────────────────────────────────────

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Database'),
        content: const Text(
          'This will replace ALL current data with the backup file. '
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedPath = result.files.single.path;
      if (pickedPath == null) return;

      final dbPath = await AppDatabase.databasePath;
      final pickedFile = File(pickedPath);
      await pickedFile.copy(dbPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Database restored! Please restart the app for changes to take effect.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SECTION HEADER
// ═════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
