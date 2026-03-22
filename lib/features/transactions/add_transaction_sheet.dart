import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../accounts/accounts_screen.dart';
import '../categories/categories_screen.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  String _category = 'Food';
  String? _selectedAccountId;
  final DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_amountController.text.isEmpty || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter amount and account')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(firestoreServiceProvider).addTransactionWithAccount(
        amount: double.parse(_amountController.text),
        type: _type,
        category: _category,
        date: _selectedDate,
        accountId: _selectedAccountId!,
        note: _noteController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _type == 'income' ? const Color(0xFF03DAC6) : const Color(0xFFCF6679);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoryAsync = ref.watch(categoryStreamProvider);

    return Container(
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _buildTypeButton('Expense', const Color(0xFFCF6679), 'expense')),
                const SizedBox(width: 12),
                Expanded(child: _buildTypeButton('Income', const Color(0xFF03DAC6), 'income')),
              ],
            ),
            const SizedBox(height: 24),
            accountsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text("Error loading accounts", style: TextStyle(color: Colors.red)),
              data: (accounts) {
                if (_selectedAccountId == null && accounts.isNotEmpty) _selectedAccountId = accounts.first.id;
                return DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  dropdownColor: const Color(0xFF2C2C2C),
                  decoration: InputDecoration(labelText: 'Account', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: activeColor),
              decoration: InputDecoration(prefixText: 'Rs ', hintText: '0.00', border: InputBorder.none),
            ),
            const SizedBox(height: 16),
            categoryAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
              data: (cats) {
                final filtered = cats.where((c) => c.type == _type).toList();
                return DropdownButtonFormField<String>(
                  value: filtered.any((c) => c.name == _category) ? _category : (filtered.isNotEmpty ? filtered.first.name : null),
                  dropdownColor: const Color(0xFF2C2C2C),
                  decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: filtered.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setState(() => _category = val!),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'What was this for?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.description, color: activeColor),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: activeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('CONFIRM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? color : Colors.white54, fontWeight: FontWeight.bold)),
      ),
    );
  }
}