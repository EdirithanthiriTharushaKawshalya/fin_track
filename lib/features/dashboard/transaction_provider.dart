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
  final selectedDate = ref.watch(
    selectedDateProvider,
  ); // Watch the selected month

  return transactionsAsync.when(
    data: (transactions) {
      double income = 0;
      double expense = 0;

      for (var t in transactions) {
        // Calculate Monthly Stats for the Balance Card
        // We EXPLICITLY check for 'income' and 'expense' only.
        // This ensures 'transfer' types are skipped for these totals.
        if (t.date.year == selectedDate.year &&
            t.date.month == selectedDate.month) {
          if (t.type == 'income') {
            income += t.amount;
          } else if (t.type == 'expense') {
            expense += t.amount;
          }
        }
      }

      return {'income': income, 'expense': expense};
    },
    loading: () => {'income': 0.0, 'expense': 0.0},
    error: (_, __) => {'income': 0.0, 'expense': 0.0},
  );
});
