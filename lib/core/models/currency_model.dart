class Currency {
  final String code;
  final String symbol;
  final String locale;

  const Currency({required this.code, required this.symbol, required this.locale});
}

const List<Currency> supportedCurrencies = [
  Currency(code: 'LKR', symbol: 'Rs ', locale: 'en_LK'),
  Currency(code: 'USD', symbol: '\$ ', locale: 'en_US'),
  Currency(code: 'EUR', symbol: '€ ', locale: 'de_DE'),
  Currency(code: 'GBP', symbol: '£ ', locale: 'en_GB'),
  Currency(code: 'INR', symbol: '₹ ', locale: 'en_IN'),
  Currency(code: 'JPY', symbol: '¥ ', locale: 'ja_JP'),
];
