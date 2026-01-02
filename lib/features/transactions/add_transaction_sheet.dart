import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Run 'flutter pub add intl' if you haven't
import '../../core/services/firestore_service.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _type = 'expense'; // Default to expense
  String _category = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Simple categories for now
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Salary',
    'Freelance',
    'Bills',
  ];

  Future<void> _submit() async {
    if (_amountController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      await _firestoreService.addTransaction(
        amount: amount,
        type: _type,
        category: _category,
        date: _selectedDate,
        note: _noteController.text,
      );

      if (mounted) Navigator.pop(context); // Close the sheet
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine color based on type
    final activeColor = _type == 'income'
        ? const Color(0xFF03DAC6)
        : const Color(0xFFCF6679);

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 24, // Handle keyboard
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

          // 2. Amount Input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: TextStyle(fontSize: 32, color: activeColor),
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 24),

          // 3. Category Dropdown
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: const Color(0xFF2C2C2C),
            items: _categories
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _category = val!),
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // 4. Save Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: activeColor),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'SAVE TRANSACTION',
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
