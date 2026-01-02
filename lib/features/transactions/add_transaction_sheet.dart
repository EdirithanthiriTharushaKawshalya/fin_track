import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/account_model.dart';
import '../../core/services/firestore_service.dart';
import '../accounts/accounts_screen.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  String _category = 'Food';
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Salary',
    'Freelance',
    'Bills',
    'Entertainment',
    'Health',
  ];

  Future<void> _submit() async {
    if (_amountController.text.isEmpty || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter amount and select an account'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      await ref
          .read(firestoreServiceProvider)
          .addTransactionWithAccount(
            amount: amount,
            type: _type,
            category: _category,
            date: _selectedDate,
            accountId: _selectedAccountId!,
            note: _noteController.text,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _type == 'income'
        ? const Color(0xFF03DAC6)
        : const Color(0xFFCF6679);
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Toggle Switch (Income vs Expense)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = 'expense'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'expense'
                          ? const Color(0xFFCF6679).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _type == 'expense'
                            ? const Color(0xFFCF6679)
                            : Colors.transparent,
                      ),
                    ),
                    child: const Text(
                      'Expense',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFCF6679),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = 'income'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'income'
                          ? const Color(0xFF03DAC6).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _type == 'income'
                            ? const Color(0xFF03DAC6)
                            : Colors.transparent,
                      ),
                    ),
                    child: const Text(
                      'Income',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF03DAC6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Account Selector (NEW)
          accountsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
            data: (accounts) {
              if (accounts.isEmpty)
                return const Text(
                  "Please add an account in 'Assets' first.",
                  style: TextStyle(color: Colors.red),
                );

              if (_selectedAccountId == null && accounts.isNotEmpty) {
                _selectedAccountId = accounts.first.id;
              }

              return DropdownButtonFormField<String>(
                value: _selectedAccountId,
                dropdownColor: const Color(0xFF2C2C2C),
                decoration: InputDecoration(
                  labelText: 'Pay with / Deposit to',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    _type == 'income'
                        ? Icons.account_balance_wallet
                        : Icons.credit_card,
                    color: activeColor,
                  ),
                ),
                items: accounts
                    .map(
                      (acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text(
                          acc.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
              );
            },
          ),

          const SizedBox(height: 16),

          // 3. Amount Input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
            decoration: InputDecoration(
              prefixText: 'Rs ',
              prefixStyle: TextStyle(fontSize: 32, color: activeColor),
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 16),

          // 4. Category Dropdown
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: const Color(0xFF2C2C2C),
            decoration: InputDecoration(
              labelText: 'Category',
              labelStyle: const TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.category, color: activeColor),
            ),
            items: _categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _category = val!),
          ),

          const SizedBox(height: 24),

          // 5. Save Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'CONFIRM TRANSACTION',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
