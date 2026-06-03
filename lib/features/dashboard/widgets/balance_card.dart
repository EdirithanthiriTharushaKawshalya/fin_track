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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      context: context,
                      ref: ref,
                      label: 'Income',
                      value: income,
                      icon: Icons.south_west_rounded,
                      color: const Color(0xFF03DAC6),
                      isDark: isDark,
                      currency: currency,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatTile(
                      context: context,
                      ref: ref,
                      label: 'Expenses',
                      value: expense,
                      icon: Icons.north_east_rounded,
                      color: const Color(0xFFFF0266),
                      isDark: isDark,
                      currency: currency,
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

  Widget _buildStatTile({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required dynamic currency,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(value, currency: currency),
              style: GoogleFonts.spaceGrotesk(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
