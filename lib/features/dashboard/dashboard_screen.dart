import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaction_model.dart';
import '../transactions/add_transaction_sheet.dart';
import 'transaction_provider.dart';
import 'widgets/balance_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the stream of transactions
    final transactionAsync = ref.watch(transactionStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'FinTrack',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. The Balance Card
            const BalanceCard(),

            const SizedBox(height: 24),

            const Text(
              'RECENT TRANSACTIONS',
              style: TextStyle(
                color: Colors.white54,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 3. The Transaction List
            Expanded(
              child: transactionAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Text(
                        "No transactions yet.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final isIncome = t.type == 'income';

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome
                                ? const Color(0xFF03DAC6).withOpacity(0.1)
                                : const Color(0xFFCF6679).withOpacity(0.1),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isIncome
                                  ? const Color(0xFF03DAC6)
                                  : const Color(0xFFCF6679),
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
                            DateFormat('MMM d, y').format(t.date),
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isIncome
                                  ? const Color(0xFF03DAC6)
                                  : const Color(0xFFCF6679),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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

      // Floating Action Button to Add Data
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB86FC),
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
