import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
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
            final dateKey = DateFormat('yyyy.MM.dd').format(t.date);
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
                  _buildSubHeader("DATA_STREAM // ${monthlyTransactions.length} ENTRIES"),
                  const SizedBox(height: 16),
                  Expanded(
                    child: monthlyTransactions.isEmpty
                        ? _buildEmptyState(selectedDate)
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
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24)),
        error: (err, _) => Center(child: Text('ERR_LOG: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildSubHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.firaCode(color: Colors.white12, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 2),
    );
  }

  Widget _buildHeader(WidgetRef ref, DateTime selectedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FIN-TRACK_TERMINAL', style: GoogleFonts.firaCode(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(DateFormat('MMMM yyyy').format(selectedDate).toUpperCase(),
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
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
        borderRadius: BorderRadius.circular(20), // More rounded corners
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white), onPressed: () => _updateMonth(ref, current, -1)),
          IconButton(icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white), onPressed: () => _updateMonth(ref, current, 1)),
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
          child: Text("TIMESTAMP: $date", style: GoogleFonts.firaCode(color: Colors.white24, fontSize: 10)),
        ),
        ...items.map((t) => _buildTransactionCard(context, ref, t)).toList(),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, dynamic t) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    // Logic: Red for Expense, Green for Income, Gray for Transfer
    final Color statusColor = isTransfer ? Colors.grey : (isIncome ? Colors.greenAccent : Colors.redAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24), // Even rounder corners
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(isTransfer ? Icons.sync_alt : (isIncome ? Icons.north_east : Icons.south_west), color: statusColor, size: 18),
        ),
        title: Text(t.category.toUpperCase(), 
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
        subtitle: Text("${DateFormat('HH:mm').format(t.date)} // ${t.note ?? 'NO_LOG'}", 
          style: GoogleFonts.firaCode(color: Colors.white24, fontSize: 10)),
        trailing: Text(
          '${isTransfer ? '' : (isIncome ? '+' : '-')}${CurrencyFormatter.format(t.amount)}',
          style: GoogleFonts.spaceGrotesk(color: statusColor, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.deepPurpleAccent, // Primary purple color
      shape: const CircleBorder(), // Fully rounded/circular
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddTransactionSheet(),
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }

  void _updateMonth(WidgetRef ref, DateTime current, int delta) {
    ref.read(selectedDateProvider.notifier).state = DateTime(current.year, current.month + delta, 1);
  }

  Widget _buildEmptyState(DateTime selectedDate) {
    return Center(
      child: Text("BUFFER_EMPTY", style: GoogleFonts.firaCode(color: Colors.white10, fontSize: 12, letterSpacing: 5)),
    );
  }
}