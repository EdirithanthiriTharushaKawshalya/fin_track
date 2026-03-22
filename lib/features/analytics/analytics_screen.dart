import 'package:fin_track/core/models/transaction_model.dart';
import 'package:fin_track/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../dashboard/transaction_provider.dart';
import '../../core/utils/currency_formatter.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _activeType = 'expense';

  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(transactionStreamProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    final Color activeColor = _activeType == 'income' 
        ? const Color(0xFF03DAC6) 
        : const Color(0xFFCF6679);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity(0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(),
              ),
            ),
          ),
          
          SafeArea(
            child: transactionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
              data: (allTransactions) {
                final monthlyData = allTransactions.where((t) {
                  return t.date.year == selectedDate.year && t.date.month == selectedDate.month;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Insights',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFloatingToggle(activeColor),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildAnalysisView(monthlyData, type: _activeType),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingToggle(Color activeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        // Changed to 100 for a fully rounded/pill shape
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _toggleButton('EXPENSES', 'expense', const Color(0xFFCF6679)),
          _toggleButton('INCOME', 'income', const Color(0xFF03DAC6)),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, String type, Color color) {
    final bool isActive = _activeType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            // Changed to 100 for fully rounded corners on the inner buttons
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isActive ? Colors.black : Colors.white24,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisView(List<TransactionModel> transactions, {required String type}) {
    final filtered = transactions.where((t) => t.type == type).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text("No transactions found", style: GoogleFonts.inter(color: Colors.white10)),
      );
    }

    final Map<String, double> categoryTotals = {};
    double total = 0;
    for (var t in filtered) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
      total += t.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildRadialChart(sortedEntries, total),
        const SizedBox(height: 40),
        Text(
          'Detailed Breakdown',
          style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ...sortedEntries.asMap().entries.map((e) => _buildCategoryCard(e.value, e.key, total)),
      ],
    );
  }

  Widget _buildRadialChart(List<MapEntry<String, double>> entries, double total) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 6,
              centerSpaceRadius: 80,
              sections: entries.asMap().entries.map((e) {
                return PieChartSectionData(
                  color: _getPaletteColor(e.key),
                  value: e.value.value,
                  title: '', 
                  radius: 20,
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TOTAL', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(total),
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(MapEntry<String, double> entry, int index, double total) {
    final double percentage = (entry.value / total) * 100;
    final Color color = _getPaletteColor(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        // Updated to be more rounded to match the aesthetic
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Center(
                child: Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    // Fully rounded progress bar
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Text(
              CurrencyFormatter.format(entry.value),
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaletteColor(int index) {
    final List<Color> palette = _activeType == 'expense' 
      ? [const Color(0xFFCF6679), const Color(0xFFBB86FC), Colors.orangeAccent, Colors.pinkAccent, Colors.deepPurpleAccent]
      : [const Color(0xFF03DAC6), Colors.blueAccent, Colors.lightGreenAccent, Colors.cyanAccent, Colors.teal];
    return palette[index % palette.length];
  }
}