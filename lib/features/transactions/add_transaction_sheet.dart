import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/account_model.dart';
import '../../core/services/firestore_service.dart';
import '../accounts/accounts_screen.dart';
import '../categories/categories_screen.dart'; // Import categories

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
  String _category = 'Food'; // Default fallback
  String? _selectedAccountId;
  final DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    // 1. WATCH THE CATEGORIES
    final categoryAsync = ref.watch(categoryStreamProvider);

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Toggle Type
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'Expense',
                    const Color(0xFFCF6679),
                    'expense',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'Income',
                    const Color(0xFF03DAC6),
                    'income',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Account Selector
            accountsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text(
                "Error loading accounts",
                style: TextStyle(color: Colors.red),
              ),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Text(
                    "Please add an account in 'Assets' first.",
                    style: TextStyle(color: Colors.red),
                  );
                }
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
                hintStyle: const TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 16),

            // 4. CATEGORY SELECTOR (The Missing Part)
            categoryAsync.when(
              loading: () => const LinearProgressIndicator(),
              // SHOW ERROR INSTEAD OF SIZEDBOX
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.1),
                child: Text(
                  'Category Error: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              data: (allCategories) {
                final availableCategories = allCategories
                    .where((c) => c.type == _type)
                    .toList();

                if (availableCategories.isEmpty) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoriesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: activeColor),
                          const SizedBox(width: 12),
                          Text(
                            "Create $_type Category +",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // If current category is invalid, switch to first available
                bool isValid = availableCategories.any(
                  (c) => c.name == _category,
                );
                if (!isValid && availableCategories.isNotEmpty) {
                  _category = availableCategories.first.name;
                }

                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: isValid
                            ? _category
                            : availableCategories.first.name,
                        dropdownColor: const Color(0xFF2C2C2C),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.category, color: activeColor),
                        ),
                        items: availableCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.name,
                                child: Row(
                                  children: [
                                    Icon(
                                      IconData(
                                        c.iconCode,
                                        fontFamily: 'MaterialIcons',
                                      ),
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white54),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // 5. Submit
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
      ),
    );
  }

  Widget _buildTypeButton(String label, Color color, String value) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.white10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
