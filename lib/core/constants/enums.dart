/// Transaction type.
enum TransactionType {
  deposit,
  withdrawal;

  String get label => switch (this) {
        TransactionType.deposit => 'Deposit',
        TransactionType.withdrawal => 'Withdrawal',
      };

  bool get isDeposit => this == TransactionType.deposit;
}

/// Supported currencies.
enum AppCurrency {
  usd('USD', '\$', 'US Dollar'),
  eur('EUR', '€', 'Euro'),
  gbp('GBP', '£', 'British Pound'),
  pkr('PKR', '₨', 'Pakistani Rupee'),
  inr('INR', '₹', 'Indian Rupee'),
  aed('AED', 'د.إ', 'UAE Dirham'),
  sar('SAR', '﷼', 'Saudi Riyal');

  const AppCurrency(this.code, this.symbol, this.name);

  final String code;
  final String symbol;
  final String name;

  /// Lookup an AppCurrency by its code string (e.g. 'EUR').
  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => AppCurrency.usd,
    );
  }
}

/// Filter period for charts / reports.
enum FilterPeriod {
  week('Last 7 Days'),
  month('Last 30 Days'),
  quarter('Last 3 Months'),
  year('Last Year'),
  all('All Time');

  const FilterPeriod(this.label);
  final String label;
}
