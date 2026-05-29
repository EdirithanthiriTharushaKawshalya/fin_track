import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../transaction_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/currency_provider.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);

    final balance = portfolio['balance'] as double;
    final income = portfolio['income'] as double;
    final expense = portfolio['expense'] as double;

    const Color primaryAccent = Color(0xFFBB86FC); 

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryAccent.withOpacity(0.12), 
            isDark ? const Color(0xFF121212) : Colors.white
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryAccent.withOpacity(isDark ? 0.08 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.account_balance_wallet, 
                color: isDark ? primaryAccent.withOpacity(0.02) : primaryAccent.withOpacity(0.05), 
                size: 180
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white54 : Colors.black45, 
                      fontSize: 13, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(balance, currency: currency),
                    style: GoogleFonts.spaceGrotesk(
                      color: isDark ? Colors.white : Colors.black, 
                      fontSize: 38, 
                      fontWeight: FontWeight.w700
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatColumn(context, ref, 'Income', income, const Color(0xFF03DAC6), Icons.arrow_downward),
                        ),
                        Container(height: 30, width: 1, color: isDark ? Colors.white10 : Colors.black12),
                        Expanded(
                          child: _buildStatColumn(context, ref, 'Expenses', expense, const Color(0xFFFF0266), Icons.arrow_upward, crossAxis: CrossAxisAlignment.end),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, WidgetRef ref, String label, double value, Color color, IconData icon, {CrossAxisAlignment crossAxis = CrossAxisAlignment.start}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (crossAxis == CrossAxisAlignment.start) Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label, 
              style: GoogleFonts.inter(
                color: isDark ? Colors.white38 : Colors.black38, 
                fontSize: 11, 
                fontWeight: FontWeight.w500
              )
            ),
            if (crossAxis == CrossAxisAlignment.end) ...[const SizedBox(width: 4), Icon(icon, color: color, size: 12)],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(value, currency: currency),
          style: GoogleFonts.spaceGrotesk(color: color, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
