import 'package:fin_track/features/dashboard/dashboard_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transaction_provider.dart';

class SpendingChart extends ConsumerWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionStreamProvider);
    // 1. ADD: Watch the selected date
    final selectedDate = ref.watch(selectedDateProvider);

    return transactionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allTransactions) {
        // 2. ADD: Filter transactions for the SELECTED month
        final expenses = allTransactions
            .where(
              (t) =>
                  t.type == 'expense' &&
                  t.date.year == selectedDate.year &&
                  t.date.month == selectedDate.month,
            )
            .toList();

        if (expenses.isEmpty) return const SizedBox.shrink();

        // 3. Group by Category
        final Map<String, double> categoryTotals = {};
        double totalExpense = 0;

        for (var t in expenses) {
          categoryTotals[t.category] =
              (categoryTotals[t.category] ?? 0) + t.amount;
          totalExpense += t.amount;
        }

        // 4. SORT: Highest Expense First (Critical for color matching)
        final sortedEntries = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // 5. Define Consistent Palette
        final colors = [
          const Color(0xFFBB86FC), // Purple (Biggest)
          const Color(0xFF03DAC6), // Teal
          const Color(0xFFCF6679), // Red
          Colors.orangeAccent,
          Colors.blueAccent,
          Colors.greenAccent,
          Colors.yellowAccent,
        ];

        int colorIndex = 0;
        final sections = sortedEntries.map((entry) {
          final percentage = (entry.value / totalExpense) * 100;
          final color = colors[colorIndex % colors.length]; // Cycle colors
          colorIndex++;

          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

        return Container(
          height: 300, // Slightly taller
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'SPENDING BREAKDOWN',
                style: TextStyle(
                  color: Colors.white54,
                  letterSpacing: 1.2,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
