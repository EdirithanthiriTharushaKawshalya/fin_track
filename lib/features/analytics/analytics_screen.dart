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
  int _touchedIndex = -1;

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
          // Background Ambient Glow
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
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
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildFloatingToggle(activeColor),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INSIGHTS', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('Analytics', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFloatingToggle(Color activeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
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
        onTap: () => setState(() {
          _activeType = type;
          _touchedIndex = -1;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isActive ? Colors.black : Colors.white24,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisView(List<TransactionModel> transactions, {required String type}) {
    final filtered = transactions.where((t) => t.type == type).toList();

    if (filtered.isEmpty) {
      return Center(child: Text("No records for this period.", style: GoogleFonts.inter(color: Colors.white10)));
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
        // Summary Header
        _buildStatDisplay('Total Monthly ${type.toUpperCase()}', total, Colors.white),
        
        const SizedBox(height: 32),
        
        // The Solid Pie Chart (No Hole)
        _buildSolidPieChart(sortedEntries, total),
        
        const SizedBox(height: 32),

        // Focus Insight Card (Interactive Detail)
        _buildFocusInsightCard(sortedEntries, categoryCounts, total),

        const SizedBox(height: 40),
        Text('DETAILED BREAKDOWN', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 16),
        
        // Restore previous Detail Cards
        ...sortedEntries.asMap().entries.map((e) => _buildPreviousDetailCard(e.value, e.key, total)),
        
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatDisplay(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.spaceGrotesk(color: color, fontSize: 28, fontWeight: FontWeight.bold),
          ),
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
          sectionsSpace: 2,
          centerSpaceRadius: 0, 
          sections: entries.asMap().entries.map((e) {
            final isTouched = e.key == _touchedIndex;
            final double radius = isTouched ? 140 : 130;
            final double opacity = isTouched ? 1.0 : 0.7;

            return PieChartSectionData(
              color: _getPaletteColor(e.key).withOpacity(opacity),
              value: e.value.value,
              title: isTouched ? '${((e.value.value / total) * 100).toStringAsFixed(0)}%' : '',
              radius: radius,
              titlePositionPercentageOffset: 0.6,
              titleStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFocusInsightCard(List<MapEntry<String, double>> entries, Map<String, int> counts, double total) {
    if (_touchedIndex == -1) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_outlined, color: Colors.white24, size: 20),
            const SizedBox(width: 12),
            Text("Select a slice to analyze specific logic", style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    final entry = entries[_touchedIndex];
    final color = _getPaletteColor(_touchedIndex);
    final count = counts[entry.key] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key.toUpperCase(), style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
              Text('${((entry.value / total) * 100).toStringAsFixed(1)}%', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(entry.value),
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Divider(color: color.withOpacity(0.1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: color.withOpacity(0.5), size: 16),
              const SizedBox(width: 8),
              Text(
                'Includes $count individual records',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Restored original Detail Card UI
  Widget _buildPreviousDetailCard(MapEntry<String, double> entry, int index, double total) {
    final double percentage = (entry.value / total) * 100;
    final Color color = _getPaletteColor(index);
    final bool isSelected = _touchedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.4) : Colors.white.withOpacity(0.03)
        ),
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
      ? [const Color(0xFFCF6679), const Color(0xFFBB86FC), const Color(0xFFFFB74D), const Color(0xFFF06292), const Color(0xFF03DAC6)]
      : [const Color(0xFF03DAC6), const Color(0xFF64B5F6), const Color(0xFF81C784), const Color(0xFF4DD0E1), const Color(0xFFFFD54F)];
    return palette[index % palette.length];
  }
}