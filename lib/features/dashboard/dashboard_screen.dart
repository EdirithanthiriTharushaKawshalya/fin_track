import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/currency_formatter.dart';
import '../transactions/add_transaction_sheet.dart';
import 'transaction_provider.dart';
import 'widgets/balance_card.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionStreamProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: transactionsAsync.when(
        data: (transactions) {
          final monthlyTransactions = transactions.where((t) {
            return t.date.year == selectedDate.year && t.date.month == selectedDate.month;
          }).toList();

          final Map<String, List<dynamic>> groupedTransactions = {};
          for (var t in monthlyTransactions) {
            final dateKey = DateFormat('EEEE, MMM d').format(t.date); 
            groupedTransactions.putIfAbsent(dateKey, () => []).add(t);
          }

          final dateKeys = groupedTransactions.keys.toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(ref, selectedDate),
                  const SizedBox(height: 24),
                  const BalanceCard(), 
                  const SizedBox(height: 32),
                  _buildSubHeader("Recent Transactions"),
                  const SizedBox(height: 16),
                  Expanded(
                    child: monthlyTransactions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            key: ValueKey(selectedDate),
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: dateKeys.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final date = dateKeys[index];
                              final items = groupedTransactions[date]!;
                              return _buildDateGroup(context, ref, date, items);
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
        error: (err, _) => Center(child: Text('Something went wrong', style: GoogleFonts.inter(color: Colors.redAccent))),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildSubHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5),
    );
  }

  Widget _buildHeader(WidgetRef ref, DateTime selectedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(DateFormat('MMMM yyyy').format(selectedDate),
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          ],
        ),
        _buildNavigationControls(ref, selectedDate),
      ],
    );
  }

  Widget _buildNavigationControls(WidgetRef ref, DateTime current) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        // Increased to circular radius for a pill shape
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFFBB86FC)), 
            onPressed: () => _updateMonth(ref, current, -1)
          ),
          Container(height: 20, width: 1, color: Colors.white.withOpacity(0.05)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFFBB86FC)), 
            onPressed: () => _updateMonth(ref, current, 1)
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(BuildContext context, WidgetRef ref, String date, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 24, bottom: 12),
          child: Text(date, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        ...items.map((t) => _buildTransactionCard(context, ref, t)).toList(),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, dynamic t) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final Color statusColor = isTransfer ? Colors.white54 : (isIncome ? const Color(0xFF03DAC6) : Colors.redAccent);

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(firestoreServiceProvider).deleteTransaction(t);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          // Matches the card rounding
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          // Increased rounding for a modern feel
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isTransfer ? Icons.sync_alt : (isIncome ? Icons.add : Icons.remove), color: statusColor, size: 20),
          ),
          title: Text(t.category, 
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(t.note ?? 'No description', 
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
          trailing: Text(
            '${isTransfer ? '' : (isIncome ? '+' : '-')}${CurrencyFormatter.format(t.amount)}',
            style: GoogleFonts.spaceGrotesk(color: statusColor, fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFBB86FC),
      elevation: 4,
      // Pill-shaped / Fully rounded FAB
      shape: const StadiumBorder(),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddTransactionSheet(),
      ),
      child: const Icon(Icons.add, color: Colors.black, size: 32),
    );
  }

  void _updateMonth(WidgetRef ref, DateTime current, int delta) {
    ref.read(selectedDateProvider.notifier).state = DateTime(current.year, current.month + delta, 1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text("No transactions this month", style: GoogleFonts.inter(color: Colors.white10, fontSize: 14)),
    );
  }
}