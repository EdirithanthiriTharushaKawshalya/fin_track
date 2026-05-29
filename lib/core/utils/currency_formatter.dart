import 'package:intl/intl.dart';
import '../models/currency_model.dart';

class CurrencyFormatter {
  static String format(double amount, {Currency? currency}) {
    final effectiveCurrency = currency ?? supportedCurrencies[0];
    final formatter = NumberFormat.currency(
      locale: effectiveCurrency.locale,
      symbol: effectiveCurrency.symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
