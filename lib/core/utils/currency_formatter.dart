import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_LK', // Sri Lankan formatting standards
      symbol: 'Rs ', // The symbol you want
      decimalDigits: 2, // Always show cents (e.g., .00)
    );
    return formatter.format(amount);
  }
}
