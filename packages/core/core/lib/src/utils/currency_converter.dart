class CurrencyConverter {
  static const Map<String, double> _rates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'INR': 83.2,
    'JPY': 150.0,
  };

  static double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    final amountInUSD = amount / (_rates[fromCurrency] ?? 1.0);
    return amountInUSD * (_rates[toCurrency] ?? 1.0);
  }
}
