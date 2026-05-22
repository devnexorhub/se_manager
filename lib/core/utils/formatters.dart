import 'package:intl/intl.dart';
import '../constants/enums.dart';

/// Utility formatters for currency, dates, etc.
class Formatters {
  Formatters._();

  /// The app-wide active currency — updated from the currency provider.
  static AppCurrency activeCurrency = AppCurrency.usd;

  /// Format a monetary amount with the active (or overridden) currency.
  static String currency(double amount, {AppCurrency? cur}) {
    final c = cur ?? activeCurrency;
    final formatter = NumberFormat.currency(
      symbol: c.symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Compact currency (e.g. €1.2K).
  static String currencyCompact(double amount, {AppCurrency? cur}) {
    final c = cur ?? activeCurrency;
    final formatter = NumberFormat.compactCurrency(
      symbol: c.symbol,
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  /// Format a date as "Apr 19, 2026".
  static String date(DateTime dt) {
    return DateFormat.yMMMd().format(dt);
  }

  /// Format a date as "Apr 19, 2026 · 2:30 PM".
  static String dateTime(DateTime dt) {
    return '${DateFormat.yMMMd().format(dt)} · ${DateFormat.jm().format(dt)}';
  }

  /// Relative time (e.g. "2 hours ago").
  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(dt);
  }
}
