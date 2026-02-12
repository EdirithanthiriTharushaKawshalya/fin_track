import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../transactions/add_transaction_sheet.dart';
import 'transaction_provider.dart';
import 'widgets/balance_card.dart';
// Note: We REMOVED the chart import because it's moved to Analytics!

// Add this at the top of the file (outside the class)
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionStreamProvider);
    final selectedDate = ref.watch(selectedDateProvider); // <--- Watch the date

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: transactionsAsync.when(
        data: (transactions) {
          // --- NEW FILTERING LOGIC ---
          // 1. Filter transactions for the SELECTED month
          final monthlyTransactions = transactions.where((t) {
            return t.date.year == selectedDate.year &&
                t.date.month == selectedDate.month;
          }).toList();

          // 2. Calculate Income/Expense using ONLY monthly data
          final income = monthlyTransactions
              .where((t) => t.type == 'income')
              .fold(0.0, (sum, t) => sum + t.amount);

          final expense = monthlyTransactions
              .where((t) => t.type == 'expense')
              .fold(0.0, (sum, t) => sum + t.amount);

          // 3. Total Balance remains ALL TIME (Current Net Worth)
          final totalBalance = transactions.fold(
            0.0,
            (sum, t) => t.type == 'income' ? sum + t.amount : sum - t.amount,
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // 1. Updated Header with Month Selector (Step 2) - With Welcome Back text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back,',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 20),

                      // --- MONTH SELECTOR ROW ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous Month Button
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              // Go back 1 month
                              ref
                                  .read(selectedDateProvider.notifier)
                                  .state = DateTime(
                                selectedDate.year,
                                selectedDate.month - 1,
                                1,
                              );
                            },
                          ),

                          // The Date Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Color(0xFFBB86FC),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMMM yyyy').format(selectedDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Next Month Button
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              // Go forward 1 month (Prevent going into the future if you want)
                              ref
                                  .read(selectedDateProvider.notifier)
                                  .state = DateTime(
                                selectedDate.year,
                                selectedDate.month + 1,
                                1,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. The Balance Card with filtered data
                  BalanceCard(
                    totalBalance: totalBalance, // Keeps real-time balance
                    income: income, // Changes based on month
                    expense: expense, // Changes based on month
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'THIS MONTH\'S ACTIVITY',
                    style: TextStyle(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. The List (Updated with ValueKey fix)
                  Expanded(
                    child: monthlyTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No transactions in ${DateFormat('MMMM').format(selectedDate)}",
                                  style: const TextStyle(color: Colors.white24),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            // key: THIS IS THE FIX.
                            // It forces the list to rebuild when the month changes.
                            key: ValueKey(selectedDate),

                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: monthlyTransactions.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final t = monthlyTransactions[index];
                              final isIncome = t.type == 'income';

                              return Dismissible(
                                key: Key(t.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFCF6679,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFCF6679),
                                    size: 28,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  ref
                                      .read(firestoreServiceProvider)
                                      .deleteTransaction(t);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Transaction reversed'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isIncome
                                            ? const Color(
                                                0xFF03DAC6,
                                              ).withOpacity(0.1)
                                            : const Color(
                                                0xFFCF6679,
                                              ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isIncome
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isIncome
                                            ? const Color(0xFF03DAC6)
                                            : const Color(0xFFCF6679),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      t.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      DateFormat(
                                        'MMM d, h:mm a',
                                      ).format(t.date),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${isIncome ? '+' : '-'}${CurrencyFormatter.format(t.amount)}',
                                      style: TextStyle(
                                        color: isIncome
                                            ? const Color(0xFF03DAC6)
                                            : const Color(0xFFCF6679),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
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
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),

      // Keep the FAB to add new items quickly
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB86FC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddTransactionSheet(),
          );
        },
      ),
    );
  }
}
