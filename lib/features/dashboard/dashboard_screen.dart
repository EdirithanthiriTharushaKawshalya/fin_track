import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: const Color(0xFF121212),
      body: transactionsAsync.when(
        data: (transactions) {
          // 1. Filter for the selected month
          final monthlyTransactions = transactions.where((t) {
            return t.date.year == selectedDate.year && t.date.month == selectedDate.month;
          }).toList();

          // 2. GROUP BY DATE LOGIC
          final Map<String, List<dynamic>> groupedTransactions = {};
          for (var t in monthlyTransactions) {
            final dateKey = DateFormat('EEEE, MMM d').format(t.date);
            if (groupedTransactions[dateKey] == null) {
              groupedTransactions[dateKey] = [];
            }
            groupedTransactions[dateKey]!.add(t);
          }

          final dateKeys = groupedTransactions.keys.toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(ref, selectedDate),
                  const SizedBox(height: 24),
                  const BalanceCard(),
                  const SizedBox(height: 32),
                  const Text('ACTIVITY BY DATE', style: TextStyle(color: Colors.white54, letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: monthlyTransactions.isEmpty
                        ? _buildEmptyState(selectedDate)
                        : ListView.builder(
                            key: ValueKey(selectedDate),
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: dateKeys.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final date = dateKeys[index];
                              final items = groupedTransactions[date]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // DATE STICKY HEADER
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                    child: Text(
                                      _isToday(items.first.date) ? "Today" : date,
                                      style: const TextStyle(color: Color(0xFFBB86FC), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  // TRANSACTIONS FOR THIS DATE
                                  ...items.map((t) => _buildTransactionCard(context, ref, t)).toList(),
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB86FC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddTransactionSheet(),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, dynamic t) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final color = isTransfer ? Colors.white54 : (isIncome ? const Color(0xFF03DAC6) : const Color(0xFFCF6679));

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(firestoreServiceProvider).deleteTransaction(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(isTransfer ? Icons.swap_horiz : (isIncome ? Icons.arrow_downward : Icons.arrow_upward), color: color, size: 18),
          ),
          title: Text(t.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (t.note != null && t.note!.isNotEmpty)
                Text(t.note!, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(DateFormat('h:mm a').format(t.date), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
          trailing: Text(
            '${isTransfer ? '' : (isIncome ? '+' : '-')}${CurrencyFormatter.format(t.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, DateTime selectedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Back,', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text(DateFormat('MMMM yyyy').format(selectedDate), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white70), onPressed: () => _updateMonth(ref, selectedDate, -1)),
            IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white70), onPressed: () => _updateMonth(ref, selectedDate, 1)),
          ],
        )
      ],
    );
  }

  void _updateMonth(WidgetRef ref, DateTime current, int delta) {
    ref.read(selectedDateProvider.notifier).state = DateTime(current.year, current.month + delta, 1);
  }

  Widget _buildEmptyState(DateTime selectedDate) {
    return Center(child: Text("No transactions in ${DateFormat('MMMM').format(selectedDate)}", style: const TextStyle(color: Colors.white24)));
  }
}