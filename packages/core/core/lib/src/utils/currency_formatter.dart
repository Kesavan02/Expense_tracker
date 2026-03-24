import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'USD'}) {
    final format = NumberFormat.simpleCurrency(name: currency);
    return format.format(amount);
  }

  static String getSymbol(String currency) {
    return NumberFormat.simpleCurrency(name: currency).currencySymbol;
  }
}
