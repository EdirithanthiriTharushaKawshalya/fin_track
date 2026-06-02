import 'package:fin_track/core/models/transaction_model.dart';
import 'package:fin_track/features/dashboard/dashboard_screen.dart';
import 'package:fin_track/core/services/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard/transaction_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/chart_theme.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _activeType = 'expense';
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(transactionStreamProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color activeColor = _activeType == 'income' 
        ? const Color(0xFF03DAC6) 
        : const Color(0xFFCF6679);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Adaptive Glow
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(isDark ? 0.05 : 0.08),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: transactionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
              error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
              data: (allTransactions) {
                final monthlyData = allTransactions.where((t) {
                  return t.date.year == selectedDate.year && t.date.month == selectedDate.month;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildFloatingToggle(context, activeColor),
                    Expanded(
                      child: _buildAnalysisView(context, monthlyData, type: _activeType),
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

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INSIGHTS', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('Analytics', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFloatingToggle(BuildContext context, Color activeColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 280, // Standardized fixed width
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            _toggleButton(context, 'EXPENSES', 'expense', const Color(0xFFCF6679)),
            _toggleButton(context, 'INCOME', 'income', const Color(0xFF03DAC6)),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(BuildContext context, String label, String type, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = _activeType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeType = type;
          _touchedIndex = -1;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isActive ? Colors.black : (isDark ? Colors.white24 : Colors.black26),
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisView(BuildContext context, List<TransactionModel> transactions, {required String type}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filtered = transactions.where((t) {
      if (type == 'income') {
        return t.type == 'income' || t.type == 'debt_borrowed' || t.type == 'debt_repayment_received';
      } else {
        return t.type == 'expense' || t.type == 'debt_lent' || t.type == 'debt_repayment_paid';
      }
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Text("No records for this period.", style: GoogleFonts.inter(color: isDark ? Colors.white10 : Colors.black12)));
    }

    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCounts = {};
    double total = 0;

    for (var t in filtered) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
      categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
      total += t.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildStatDisplay(context, 'Total Monthly ${type.toUpperCase()}', total, isDark ? Colors.white : Colors.black),
        const SizedBox(height: 32),
        _buildSolidPieChart(sortedEntries, total),
        const SizedBox(height: 32),
        _buildFocusInsightCard(context, sortedEntries, categoryCounts, total),
        const SizedBox(height: 40),
        Text('DETAILED BREAKDOWN', style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 16),
        ...sortedEntries.asMap().entries.map((e) => _buildPreviousDetailCard(context, e.value, e.key, total, sortedEntries.length)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatDisplay(BuildContext context, String label, double amount, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.format(amount, currency: currency), style: GoogleFonts.spaceGrotesk(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSolidPieChart(List<MapEntry<String, double>> entries, double total) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 1.5,
          centerSpaceRadius: 0, 
          sections: entries.asMap().entries.map((e) {
            final isTouched = e.key == _touchedIndex;
            final color = _getPaletteColor(e.key, entries.length);
            final sliceColor = isTouched ? color.withOpacity(1.0) : color;

            return PieChartSectionData(
              color: sliceColor,
              value: e.value.value,
              showTitle: false,
              radius: isTouched ? 100 : 90,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFocusInsightCard(BuildContext context, List<MapEntry<String, double>> entries, Map<String, int> counts, double total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    if (_touchedIndex == -1) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app_outlined, color: isDark ? Colors.white24 : Colors.black26, size: 20),
            const SizedBox(width: 12),
            Text("Select a slice to analyze specific logic", style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13)),
          ],
        ),
      );
    }

    final entry = entries[_touchedIndex];
    final color = _getPaletteColor(_touchedIndex, entries.length);
    final count = counts[entry.key] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: isDark ? [] : [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key.toUpperCase(), style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
              Text('${((entry.value / total) * 100).toStringAsFixed(1)}%', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(CurrencyFormatter.format(entry.value, currency: currency), style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Divider(color: color.withOpacity(0.1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: color.withOpacity(0.5), size: 16),
              const SizedBox(width: 8),
              Text('Includes $count individual records', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousDetailCard(BuildContext context, MapEntry<String, double> entry, int index, double total, int totalCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    final double percentage = (entry.value / total) * 100;
    final Color color = _getPaletteColor(index, totalCount);
    final bool isSelected = _touchedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isSelected ? color.withOpacity(0.4) : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05))),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              height: 45, width: 45,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Center(child: Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: percentage / 100, minHeight: 5,
                      backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Text(CurrencyFormatter.format(entry.value, currency: currency), style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Color _getPaletteColor(int index, int totalCount) {
    return ChartTheme.getMonochromaticColor(index, totalCount, _activeType);
  }
}
