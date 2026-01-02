import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/debt_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/currency_formatter.dart'; // Import the formatter

// Provider for Debts
final debtsStreamProvider = StreamProvider<List<DebtModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getDebts();
});

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Debt Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFBB86FC),
          labelColor: const Color(0xFFBB86FC),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'I OWE (Borrowed)'),
            Tab(text: 'OWED TO ME (Lent)'),
          ],
        ),
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (allDebts) {
          // Filter the lists
          final borrowed = allDebts.where((d) => d.type == 'borrowed').toList();
          final lent = allDebts.where((d) => d.type == 'lent').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDebtList(borrowed, isBorrowed: true),
              _buildDebtList(lent, isBorrowed: false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB86FC),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showAddDebtDialog(context),
      ),
    );
  }

  Widget _buildDebtList(List<DebtModel> debts, {required bool isBorrowed}) {
    if (debts.isEmpty) {
      return const Center(
        child: Text(
          "Clean slate. No records.",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        final color = isBorrowed
            ? const Color(0xFFCF6679)
            : const Color(0xFF03DAC6);

        return Dismissible(
          key: Key(debt.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.green.withOpacity(0.2), // Green for "Settled"
            child: const Icon(Icons.check, color: Colors.green),
          ),
          onDismissed: (_) {
            ref.read(firestoreServiceProvider).deleteDebt(debt.id);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Marked as Settled')));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Text(
                    debt.personName[0].toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.personName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Due: ${DateFormat('MMM d').format(debt.dueDate)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // UPDATED: Using CurrencyFormatter
                Text(
                  CurrencyFormatter.format(debt.amount),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    // Default to the current tab
    String type = _tabController.index == 0 ? 'borrowed' : 'lent';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('New Record', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Person Name'),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              // UPDATED: Added prefixText for input
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs ',
                prefixStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              dropdownColor: const Color(0xFF2C2C2C),
              items: const [
                DropdownMenuItem(
                  value: 'borrowed',
                  child: Text(
                    'I Borrowed (Owe)',
                    style: TextStyle(color: Color(0xFFCF6679)),
                  ),
                ),
                DropdownMenuItem(
                  value: 'lent',
                  child: Text(
                    'I Lent (Owed to me)',
                    style: TextStyle(color: Color(0xFF03DAC6)),
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
            child: const Text(
              'SAVE',
              style: TextStyle(color: Color(0xFFBB86FC)),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                ref
                    .read(firestoreServiceProvider)
                    .addDebt(
                      personName: nameCtrl.text,
                      amount: double.parse(amountCtrl.text),
                      type: type,
                      dueDate: DateTime.now().add(
                        const Duration(days: 14),
                      ), // Default 2 weeks
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
