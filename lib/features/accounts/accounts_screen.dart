import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/account_model.dart';
import '../../core/services/firestore_service.dart';

final accountsStreamProvider = StreamProvider<List<AccountModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAccounts();
});

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'My Assets',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            onPressed: () => _showAddAccountDialog(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Text(
                "Add your Bank Accounts or Wallet",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final acc = accounts[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Glassmorphism Gradient based on card color
                  gradient: LinearGradient(
                    colors: [
                      Color(acc.colorCode).withOpacity(0.8),
                      Color(acc.colorCode).withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(acc.colorCode).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          acc.type == 'bank'
                              ? Icons.account_balance
                              : Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 30,
                        ),
                        const Icon(Icons.more_horiz, color: Colors.white70),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      acc.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${acc.currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String type = 'bank'; // Default
    int selectedColor = 0xFFBB86FC; // Default Purple

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Asset', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Account Name (e.g., HNB)',
              ),
            ),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Current Balance'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              dropdownColor: const Color(0xFF2C2C2C),
              items: const [
                DropdownMenuItem(
                  value: 'bank',
                  child: Text(
                    'Bank Account',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                DropdownMenuItem(
                  value: 'wallet',
                  child: Text(
                    'Physical Wallet',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              onChanged: (val) => type = val!,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('CREATE'),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && balanceCtrl.text.isNotEmpty) {
                ref
                    .read(firestoreServiceProvider)
                    .addAccount(
                      name: nameCtrl.text,
                      initialBalance: double.parse(balanceCtrl.text),
                      type: type,
                      colorCode: type == 'bank'
                          ? 0xFF3700B3
                          : 0xFF03DAC6, // Auto-color based on type
                    );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
