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
  String _category = ''; 
  String? _selectedAccountId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = _type == 'income' ? const Color(0xFF03DAC6) : const Color(0xFFCF6679);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoryAsync = ref.watch(categoryStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(top: 20, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            
            _buildTypeToggle(activeColor, isDark),
            const SizedBox(height: 32),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                prefixText: 'Rs ',
                prefixStyle: GoogleFonts.inter(color: activeColor, fontSize: 20, fontWeight: FontWeight.w600),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 32),

            _buildInputWrapper(
              context: context,
              child: accountsAsync.when(
                data: (accounts) {
                  if (_selectedAccountId == null && accounts.isNotEmpty) _selectedAccountId = accounts.first.id;
                  return DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
                    style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500, fontSize: 14),
                    items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                    decoration: _fieldDecoration(context, 'Payment Account', Icons.account_balance_wallet_rounded),
                  );
                },
                loading: () => const LinearProgressIndicator(color: Colors.white10),
                error: (_, __) => const Text("Error loading accounts"),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInputWrapper(
              context: context,
              child: categoryAsync.when(
                data: (cats) {
                  final filtered = cats.where((c) => c.type == _type).toList();
                  final currentCat = filtered.any((c) => c.name == _category) 
                      ? _category 
                      : (filtered.isNotEmpty ? filtered.first.name : null);
                  
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currentCat,
                          dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
                          style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500, fontSize: 14),
                          items: filtered.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                          onChanged: (val) => setState(() => _category = val!),
                          decoration: _fieldDecoration(context, 'Category', Icons.category_rounded),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen())),
                          icon: Icon(Icons.settings_outlined, color: activeColor.withOpacity(0.7), size: 16),
                          label: Text("Manage", style: GoogleFonts.inter(color: activeColor.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            backgroundColor: activeColor.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(color: Colors.white10),
                error: (_, __) => const Text("Error loading categories"),
              ),
            ),
            const SizedBox(height: 16),

            _buildInputWrapper(
              context: context,
              child: TextField(
                controller: _noteController,
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                decoration: _fieldDecoration(context, 'Notes', Icons.description_rounded),
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

  Widget _buildTypeToggle(Color activeColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(20), 
      ),
      child: Row(
        children: [
          _togglePart('Expense', 'expense', const Color(0xFFCF6679), isDark),
          _togglePart('Income', 'income', const Color(0xFF03DAC6), isDark),
        ],
      ),
    );
  }

  Widget _togglePart(String label, String value, Color color, bool isDark) {
    final isSelected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = value;
          _category = ''; 
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent, 
            borderRadius: BorderRadius.circular(16), 
          ),
          child: Text(
            label, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.inter(
              color: isSelected ? Colors.black : (isDark ? Colors.white38 : Colors.black26), 
              fontWeight: FontWeight.bold, 
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputWrapper({required BuildContext context, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 22),
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Future<void> _submit() async {
    if (_amountController.text.isEmpty || _selectedAccountId == null) return;
    
    final categories = ref.read(categoryStreamProvider).value ?? [];
    final filtered = categories.where((c) => c.type == _type).toList();
    
    String finalCategory = _category;
    if (!filtered.any((c) => c.name == _category)) {
      if (filtered.isNotEmpty) {
        finalCategory = filtered.first.name;
      } else {
        finalCategory = 'General';
      }
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(firestoreServiceProvider).addTransactionWithAccount(
        amount: double.parse(_amountController.text),
        type: _type,
        category: finalCategory,
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