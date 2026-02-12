import 'package:fin_track/core/models/transaction_model.dart';
import 'package:fin_track/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/transaction_provider.dart';
import '../dashboard/widgets/spending_chart.dart';
import '../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 tabs: Expenses and Income
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(transactionStreamProvider);
    // 1. ADD: Watch the global selected date from the Dashboard
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Financial Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Add the TabBar here to match your design style
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFBB86FC),
          labelColor: const Color(0xFFBB86FC),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'EXPENSES'),
            Tab(text: 'INCOME'),
          ],
        ),
      ),
      body: transactionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allTransactions) {
          // Filter transactions for the SELECTED month globally
          final monthlyData = allTransactions.where((t) {
            return t.date.year == selectedDate.year &&
                t.date.month == selectedDate.month;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAnalysisView(monthlyData, type: 'expense'),
              _buildAnalysisView(monthlyData, type: 'income'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalysisView(
    List<TransactionModel> transactions, {
    required String type,
  }) {
    final filtered = transactions.where((t) => t.type == type).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          "No ${type}s found for this month.",
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    // Grouping logic for the specific type
    final Map<String, double> categoryTotals = {};
    double total = 0;
    for (var t in filtered) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
      total += t.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Reusable chart that now accepts a type
          SpendingChart(type: type),
          const SizedBox(height: 32),
          // Helper method to build the category list with progress bars
          ..._buildCategoryList(sortedCategories, total, type),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  List<Widget> _buildCategoryList(
    List<MapEntry<String, double>> sortedCategories,
    double total,
    String type,
  ) {
    final bool isExpense = type == 'expense';

    if (sortedCategories.isEmpty) {
      return [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Center(
            child: Text(
              'No ${isExpense ? 'expenses' : 'income'} in this month',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ];
    }

    // Color Palette (Must match the Chart palette!)
    final colors = isExpense
        ? [
            const Color(0xFFBB86FC), // Purple
            const Color(0xFFCF6679), // Red
            Colors.orangeAccent,
            Colors.pinkAccent,
            Colors.deepPurpleAccent,
            Colors.redAccent,
            Colors.amber,
          ]
        : [
            const Color(0xFF03DAC6), // Teal
            Colors.greenAccent,
            Colors.lightGreenAccent,
            Colors.lightBlueAccent,
            Colors.cyanAccent,
            Colors.tealAccent,
            Colors.limeAccent,
          ];

    return sortedCategories.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;

      final percentage = (entry.value / total);
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
    }).toList();
  }
}
