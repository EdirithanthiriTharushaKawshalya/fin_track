import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/firestore_service.dart';

// 1. The Service Provider (Gives access to FirestoreService)
final firestoreServiceProvider = Provider((ref) => FirestoreService());

// 2. The Data Stream (Listens to the database)
final transactionStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTransactions();
});

// 3. The Math (Calculates Totals automatically)
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
