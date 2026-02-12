import 'package:fin_track/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/transaction_provider.dart';
import '../dashboard/widgets/spending_chart.dart';
import '../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionStreamProvider);
    // 1. ADD: Watch the global selected date from the Dashboard
    final selectedDate = ref.watch(selectedDateProvider);

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
        data: (allTransactions) {
          // 2. ADD: Filter transactions for the SELECTED month
          final monthlyTransactions = allTransactions.where((t) {
            return t.date.year == selectedDate.year &&
                t.date.month == selectedDate.month;
          }).toList();

          // 3. UPDATE: Filter ONLY expenses from the monthly list
          final expenses = monthlyTransactions
              .where((t) => t.type == 'expense')
              .toList();

          // If no expenses in the selected month, show empty state
          if (expenses.isEmpty) {
            return Center(
              child: Text(
                "No expenses in ${DateFormat('MMMM yyyy').format(selectedDate)}",
                style: const TextStyle(color: Colors.white54),
              ),
            );
          }

          // 2. Group & Total
          final Map<String, double> categoryTotals = {};
          double totalExpense = 0;
          for (var t in expenses) {
            categoryTotals[t.category] =
                (categoryTotals[t.category] ?? 0) + t.amount;
            totalExpense += t.amount;
          }

          // 3. SORT: Highest First (Must match the Chart logic!)
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // 4. Color Palette (Must match the Chart palette!)
          final colors = [
            const Color(0xFFBB86FC), // Purple
            const Color(0xFF03DAC6), // Teal
            const Color(0xFFCF6679), // Red
            Colors.orangeAccent,
            Colors.blueAccent,
            Colors.greenAccent,
            Colors.yellowAccent,
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The Chart
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

                // The List (Now with matching colors)
                // We use .asMap() to get the index so we can pick the right color
                ...sortedCategories.asMap().entries.map((mapEntry) {
                  final index = mapEntry.key;
                  final entry = mapEntry.value;

                  final percentage = (entry.value / totalExpense);
                  // Assign color based on index, looping if we run out of colors
                  final color = colors[index % colors.length];

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
                            Row(
                              children: [
                                // Colored Dot indicator
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.format(entry.value),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress Bar matching the color
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.white10,
                            color: color, // <--- Matching Color
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
