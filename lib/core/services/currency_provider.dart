import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/currency_model.dart';
import 'preferences_service.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<Currency> {
  CurrencyNotifier() : super(supportedCurrencies[0]) {
    _loadCurrency();
  }

  final _prefs = PreferencesService();

  Future<void> _loadCurrency() async {
    final code = await _prefs.getCurrency();
    state = supportedCurrencies.firstWhere((c) => c.code == code, orElse: () => supportedCurrencies[0]);
  }

  Future<void> setCurrency(String code) async {
    await _prefs.setCurrency(code);
    state = supportedCurrencies.firstWhere((c) => c.code == code, orElse: () => supportedCurrencies[0]);
  }
}
