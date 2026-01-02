import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/firestore_service.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

// 1. Logic: Filter for THIS MONTH only
final transactionStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);

  return firestoreService.getTransactions().map((allTransactions) {
    final now = DateTime.now();
    // Keep only transactions from the current year AND month
    return allTransactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();
  });
});

// 2. Logic: Recalculate Totals based on the filtered list
final portfolioProvider = Provider.autoDispose((ref) {
  final transactionsAsync = ref.watch(transactionStreamProvider);

  return transactionsAsync.when(
    data: (transactions) {
      double income = 0;
      double expense = 0;

      for (var t in transactions) {
        if (t.type == 'income') {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }

      return {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    },
    loading: () => {'income': 0.0, 'expense': 0.0, 'balance': 0.0},
    error: (_, __) => {'income': 0.0, 'expense': 0.0, 'balance': 0.0},
  );
});
