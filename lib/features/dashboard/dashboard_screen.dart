import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/transaction_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../transactions/add_transaction_sheet.dart';
import 'transaction_provider.dart';
import 'widgets/balance_card.dart';
// Note: We REMOVED the chart import because it's moved to Analytics!

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionStreamProvider);
    final String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 1. Top Header (Clean & Minimal)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentMonth,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {}, // Future feature
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. The Balance Card (Now shows ONLY monthly data)
              const BalanceCard(),

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

              // 3. The List (Cleaned up visuals)
              Expanded(
                child: transactionAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No activity this month.",
                              style: TextStyle(color: Colors.white24),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: transactions.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final t = transactions[index];
                        final isIncome = t.type == 'income';

                        return Dismissible(
                          key: Key(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCF6679).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFCF6679),
                              size: 28,
                            ),
                          ),
                          onDismissed: (direction) {
                            // Assuming you have the delete method in your provider or service
                            // ref.read(firestoreServiceProvider).deleteTransaction(t.id);
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
                                      ? const Color(0xFF03DAC6).withOpacity(0.1)
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
                                DateFormat('MMM d, h:mm a').format(t.date),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Text(
                                // Clean logic: Plus/Minus sign + Formatted Amount
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
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
