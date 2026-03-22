import 'package:fin_track/features/accounts/accounts_screen.dart';
import 'package:fin_track/features/categories/categories_screen.dart';
import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = _type == 'income' ? const Color(0xFF03DAC6) : const Color(0xFFCF6679);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoryAsync = ref.watch(categoryStreamProvider);

    return Container(
      padding: EdgeInsets.only(top: 20, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
      decoration: const BoxDecoration(
        color: Color(0xFF080808),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            
            _buildTypeToggle(activeColor),
            const SizedBox(height: 32),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.05)),
                prefixText: 'Rs ',
                prefixStyle: GoogleFonts.inter(color: activeColor, fontSize: 20, fontWeight: FontWeight.w600),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 32),

            _buildInputWrapper(
              child: accountsAsync.when(
                data: (accounts) {
                  if (_selectedAccountId == null && accounts.isNotEmpty) _selectedAccountId = accounts.first.id;
                  return DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    dropdownColor: const Color(0xFF121212),
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                    items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                    decoration: _fieldDecoration('Payment Account', Icons.account_balance_wallet_rounded),
                  );
                },
                loading: () => const LinearProgressIndicator(color: Colors.white10),
                error: (_, __) => const Text("Error loading accounts"),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInputWrapper(
              child: categoryAsync.when(
                data: (cats) {
                  final filtered = cats.where((c) => c.type == _type).toList();
                  final currentCat = filtered.any((c) => c.name == _category) ? _category : (filtered.isNotEmpty ? filtered.first.name : null);
                  return DropdownButtonFormField<String>(
                    value: currentCat,
                    dropdownColor: const Color(0xFF121212),
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                    items: filtered.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _category = val!),
                    decoration: _fieldDecoration('Category', Icons.category_rounded),
                  );
                },
                loading: () => const LinearProgressIndicator(color: Colors.white10),
                error: (_, __) => const Text("Error loading categories"),
              ),
            ),
            const SizedBox(height: 16),

            _buildInputWrapper(
              child: TextField(
                controller: _noteController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: _fieldDecoration('Notes', Icons.description_rounded),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.black,
                  // Changed to a much rounder pill shape
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                  : Text(
                      'Save Transaction',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(Color activeColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(20), // Rounder container
      ),
      child: Row(
        children: [
          _togglePart('Expense', 'expense', const Color(0xFFCF6679)),
          _togglePart('Income', 'income', const Color(0xFF03DAC6)),
        ],
      ),
    );
  }

  Widget _togglePart(String label, String value, Color color) {
    final isSelected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent, 
            borderRadius: BorderRadius.circular(16), // Rounder toggle buttons
          ),
          child: Text(
            label, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.inter(
              color: isSelected ? Colors.black : Colors.white24, 
              fontWeight: FontWeight.bold, 
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24), // Matches the card rounding from other screens
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(icon, color: Colors.white38, size: 22),
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Future<void> _submit() async {
    if (_amountController.text.isEmpty || _selectedAccountId == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(firestoreServiceProvider).addTransactionWithAccount(
        amount: double.parse(_amountController.text),
        type: _type,
        category: _category,
        date: DateTime.now(),
        accountId: _selectedAccountId!,
        note: _noteController.text.trim(),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}