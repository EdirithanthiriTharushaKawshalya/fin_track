import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transaction_provider.dart';

class SpendingChart extends ConsumerWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionStreamProvider);

    return transactionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (transactions) {
        // 1. Filter only expenses
        final expenses = transactions
            .where((t) => t.type == 'expense')
            .toList();

        if (expenses.isEmpty) return const SizedBox.shrink();

        // 2. Group by Category
        final Map<String, double> categoryTotals = {};
        double totalExpense = 0;

        for (var t in expenses) {
          categoryTotals[t.category] =
              (categoryTotals[t.category] ?? 0) + t.amount;
          totalExpense += t.amount;
        }

        // 3. Create Chart Data
        // Define some neon colors for the futuristic look
        final colors = [
          const Color(0xFFBB86FC), // Purple
          const Color(0xFF03DAC6), // Teal
          const Color(0xFFCF6679), // Red
          const Color(0xFF3700B3), // Dark Blue
          Colors.orangeAccent,
        ];

        int colorIndex = 0;
        final sections = categoryTotals.entries.map((entry) {
          final percentage = (entry.value / totalExpense) * 100;
          final color = colors[colorIndex % colors.length];
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
          height: 250,
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
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
              const SizedBox(height: 24),
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
