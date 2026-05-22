import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/student_dao.dart';
import '../data/database/daos/transaction_dao.dart';

// ═══════════════════════════════════════════════════════════════════════
//  SHARED PREFERENCES
// ═══════════════════════════════════════════════════════════════════════

/// SharedPreferences instance – must be initialised before runApp().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a real instance.',
  );
});

// ═══════════════════════════════════════════════════════════════════════
//  DATABASE
// ═══════════════════════════════════════════════════════════════════════

/// Singleton database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// DAO providers.
final studentDaoProvider = Provider<StudentDao>((ref) {
  return ref.watch(databaseProvider).studentDao;
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return ref.watch(databaseProvider).transactionDao;
});

// ═══════════════════════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════════════════════

const _kThemeModeKey = 'theme_mode';

/// Theme mode state (light / dark / system) — persisted via SharedPreferences.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_loadFromPrefs(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _loadFromPrefs(SharedPreferences prefs) {
    final saved = prefs.getString(_kThemeModeKey);
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _persist(ThemeMode mode) {
    _prefs.setString(_kThemeModeKey, mode.name);
  }

  void setLight() {
    state = ThemeMode.light;
    _persist(state);
  }

  void setDark() {
    state = ThemeMode.dark;
    _persist(state);
  }

  void setSystem() {
    state = ThemeMode.system;
    _persist(state);
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persist(state);
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CURRENCY
// ═══════════════════════════════════════════════════════════════════════

const _kCurrencyKey = 'currency_code';

/// Selected currency code — persisted via SharedPreferences.
final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrencyNotifier(prefs);
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier(this._prefs)
      : super(_prefs.getString(_kCurrencyKey) ?? 'USD');

  final SharedPreferences _prefs;

  void setCurrency(String code) {
    state = code;
    _prefs.setString(_kCurrencyKey, code);
  }
}
