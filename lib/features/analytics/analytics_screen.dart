import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/widgets/spending_chart.dart';
import '../dashboard/transaction_provider.dart';
import '../../core/utils/currency_formatter.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: transactionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (transactions) {
          // 1. Filter Expenses Only
          final expenses = transactions
              .where((t) => t.type == 'expense')
              .toList();
          if (expenses.isEmpty) {
            return const Center(
              child: Text(
                "No expenses to analyze.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          // 2. Calculate Totals by Category
          final Map<String, double> categoryTotals = {};
          double totalExpense = 0;
          for (var t in expenses) {
            categoryTotals[t.category] =
                (categoryTotals[t.category] ?? 0) + t.amount;
            totalExpense += t.amount;
          }

          // 3. Convert to List & Sort
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)); // Highest first

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CHART SECTION
                const SpendingChart(),

                const SizedBox(height: 32),
                const Text(
                  'TOP SPENDING CATEGORIES',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // BREAKDOWN LIST
                ...sortedCategories.map((entry) {
                  final percentage = (entry.value / totalExpense);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(entry.value),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Mini Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.white10,
                            color: const Color(0xFFBB86FC),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
