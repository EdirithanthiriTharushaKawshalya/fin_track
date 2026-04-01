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
          // Ambient Glow
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
          _touchedIndex = -1; // Reset selection on toggle
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
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
        child: Text("No records found for this month", style: GoogleFonts.inter(color: Colors.white10)),
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
        _buildProfessionalChart(sortedEntries, total),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DETAILED BREAKDOWN',
              style: GoogleFonts.inter(
                color: Colors.white38, 
                fontWeight: FontWeight.w800, 
                fontSize: 10, 
                letterSpacing: 1.5
              ),
            ),
            Text(
              '${sortedEntries.length} CATEGORIES',
              style: GoogleFonts.inter(color: Colors.white10, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...sortedEntries.asMap().entries.map((e) => _buildCategoryCard(e.value, e.key, total)),
        const SizedBox(height: 100), // FAB spacing
      ],
    );
  }

  Widget _buildProfessionalChart(List<MapEntry<String, double>> entries, double total) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 75,
              sections: entries.asMap().entries.map((e) {
                final isTouched = e.key == _touchedIndex;
                final double fontSize = isTouched ? 18 : 12;
                final double radius = isTouched ? 35 : 28;
                final double opacity = isTouched ? 1.0 : 0.8;

                return PieChartSectionData(
                  color: _getPaletteColor(e.key).withOpacity(opacity),
                  value: e.value.value,
                  title: isTouched ? '${((e.value.value / total) * 100).toStringAsFixed(0)}%' : '',
                  radius: radius,
                  titleStyle: GoogleFonts.spaceGrotesk(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: isTouched ? _buildChartBadge(e.value.key, _getPaletteColor(e.key)) : null,
                  badgePositionPercentageOffset: 1.3,
                );
              }).toList(),
            ),
          ),
          // Central Info Display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _touchedIndex == -1 ? 'TOTAL ${_activeType.toUpperCase()}' : entries[_touchedIndex].key.toUpperCase(),
                style: GoogleFonts.inter(
                  color: Colors.white38, 
                  fontSize: 9, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _touchedIndex == -1 
                  ? CurrencyFormatter.format(total) 
                  : CurrencyFormatter.format(entries[_touchedIndex].value),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
              ),
              if (_touchedIndex != -1) ...[
                const SizedBox(height: 4),
                Text(
                  '${((entries[_touchedIndex].value / total) * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    color: _getPaletteColor(_touchedIndex), 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBadge(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryCard(MapEntry<String, double> entry, int index, double total) {
    final double percentage = (entry.value / total) * 100;
    final Color color = _getPaletteColor(index);
    final bool isSelected = _touchedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.5) : Colors.white.withOpacity(0.03),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15)] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => setState(() => _touchedIndex = isSelected ? -1 : index),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1), 
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.2))
                  ),
                  child: Center(
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%', 
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key, 
                        style: GoogleFonts.inter(
                          color: Colors.white, 
                          fontWeight: FontWeight.w700, 
                          fontSize: 15
                        )
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            height: 6,
                            width: (MediaQuery.of(context).size.width - 180) * (percentage / 100),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [color, color.withOpacity(0.5)]),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)]
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'LKR',
                      style: GoogleFonts.inter(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPaletteColor(int index) {
    final List<Color> palette = _activeType == 'expense' 
      ? [
          const Color(0xFFCF6679), // Soft Red
          const Color(0xFFBB86FC), // Vivid Purple
          const Color(0xFFFFB74D), // Orange
          const Color(0xFFF06292), // Pink
          const Color(0xFF7E57C2), // Deep Purple
          const Color(0xFFFF8A65), // Deep Orange
        ]
      : [
          const Color(0xFF03DAC6), // Teal
          const Color(0xFF64B5F6), // Blue
          const Color(0xFF81C784), // Green
          const Color(0xFF4DD0E1), // Cyan
          const Color(0xFFAED581), // Light Green
          const Color(0xFF4FC3F7), // Light Blue
        ];
    return palette[index % palette.length];
  }
}