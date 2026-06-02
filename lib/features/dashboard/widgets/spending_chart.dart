import 'package:fin_track/features/dashboard/dashboard_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/utils/chart_theme.dart';
import '../transaction_provider.dart';

class SpendingChart extends ConsumerWidget {
  final String type; // 'expense' or 'income'
  const SpendingChart({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionStreamProvider);
    // 1. Watch the selected date
    final selectedDate = ref.watch(selectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return transactionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allTransactions) {
        // 2. Filter transactions for the SELECTED month and type
        final filtered = allTransactions
            .where(
              (t) =>
                  t.type == type &&
                  t.date.year == selectedDate.year &&
                  t.date.month == selectedDate.month,
            )
            .toList();

        if (filtered.isEmpty) return const SizedBox.shrink();

        // 3. Group by Category
        final Map<String, double> categoryTotals = {};

        for (var t in filtered) {
          categoryTotals[t.category] =
              (categoryTotals[t.category] ?? 0) + t.amount;
        }

        // 4. SORT: Highest First (Critical for color matching)
        final sortedEntries = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        int colorIndex = 0;
        final sections = sortedEntries.map((entry) {
          final color = ChartTheme.getMonochromaticColor(
              colorIndex, sortedEntries.length, type);
          colorIndex++;

          return PieChartSectionData(
            color: color,
            value: entry.value,
            showTitle: false,
            radius: 65,
          );
        }).toList();

        return Container(
          height: 300,
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Text(
                type == 'expense' ? 'EXPENSE BREAKDOWN' : 'INCOME BREAKDOWN',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white54 : Colors.black54,
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 0,
                    sectionsSpace: 1.5,
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
