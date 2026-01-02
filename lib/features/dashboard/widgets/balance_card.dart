import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transaction_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the math provider we just created
    final portfolio = ref.watch(portfolioProvider);

    final balance = portfolio['balance'] as double;
    final income = portfolio['income'] as double;
    final expense = portfolio['expense'] as double;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Futuristic Gradient Background
        gradient: const LinearGradient(
          colors: [Color(0xFFBB86FC), Color(0xFF3700B3)], // Purple to Deep Blue
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
              // Income
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: Color(0xFF03DAC6),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'INCOME',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(income),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Expense
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: Color(0xFFCF6679),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'EXPENSE',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(expense),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
