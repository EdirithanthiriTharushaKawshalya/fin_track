import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transaction_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class BalanceCard extends ConsumerWidget {
  // REMOVED: The manual double parameters.
  // We let the widget fetch its own data from the provider.
  const BalanceCard({
    super.key,
    required double totalBalance,
    required double income,
    required double expense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the recalculated math provider
    final portfolio = ref.watch(portfolioProvider);

    final balance = portfolio['balance'] as double;
    final income = portfolio['income'] as double;
    final expense = portfolio['expense'] as double;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBB86FC), Color(0xFF3700B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBB86FC).withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL BALANCE',
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 1.5,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                'INCOME',
                income,
                const Color(0xFF03DAC6),
                Icons.arrow_downward,
              ),
              _buildStatColumn(
                'EXPENSE',
                expense,
                const Color(0xFFCF6679),
                Icons.arrow_upward,
                crossAxis: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to keep the code DRY (Don't Repeat Yourself)
  Widget _buildStatColumn(
    String label,
    double value,
    Color color,
    IconData icon, {
    CrossAxisAlignment crossAxis = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        Text(
          CurrencyFormatter.format(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
