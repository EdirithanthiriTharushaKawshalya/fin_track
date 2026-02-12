import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaction_model.dart';
import '../../core/services/firestore_service.dart';
import '../dashboard/dashboard_screen.dart'; // Import for selectedDateProvider

final firestoreServiceProvider = Provider((ref) => FirestoreService());

// 1. First, make sure the stream sends ALL transactions (no filtering here)
final transactionStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTransactions(); // Provide the full list
});

// 2. Update the portfolioProvider to watch the selected date
final portfolioProvider = Provider.autoDispose((ref) {
  final transactionsAsync = ref.watch(transactionStreamProvider);
  final selectedDate = ref.watch(selectedDateProvider); // <--- WATCH THE DATE

  return transactionsAsync.when(
    data: (transactions) {
      double income = 0;
      double expense = 0;
      double totalBalance = 0;

      for (var t in transactions) {
        // A. Always calculate Total Balance (Your overall Net Worth)
        if (t.type == 'income') {
          totalBalance += t.amount;
        } else {
          totalBalance -= t.amount;
        }

        // B. ONLY add to Income/Expense if it matches the SELECTED month
        if (t.date.year == selectedDate.year &&
            t.date.month == selectedDate.month) {
          if (t.type == 'income') {
            income += t.amount;
          } else {
            expense += t.amount;
          }
        }
      }

      return {'income': income, 'expense': expense, 'balance': totalBalance};
    },
    loading: () => {'income': 0.0, 'expense': 0.0, 'balance': 0.0},
    error: (_, __) => {'income': 0.0, 'expense': 0.0, 'balance': 0.0},
  );
});
