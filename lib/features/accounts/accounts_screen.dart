import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:fin_track/core/services/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../core/models/account_model.dart';
import '../../core/utils/currency_formatter.dart';

final accountsStreamProvider = StreamProvider<List<AccountModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAccounts();
});

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context, ref),
              const SizedBox(height: 32),
              _buildSubHeader(context, "Your Assets"),
              const SizedBox(height: 16),
              Expanded(
                child: accountsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
                  error: (err, _) => Center(child: Text('Error loading accounts', style: GoogleFonts.inter(color: Colors.redAccent))),
                  data: (accounts) {
                    if (accounts.isEmpty) return _buildEmptyState(context);
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: accounts.length,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildAssetCard(context, ref, accounts[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context, ref),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('My Accounts', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 28, fontWeight: FontWeight.w700)),
          ],
        ),
        IconButton(
          onPressed: () => _showTransferDialog(context, ref),
          icon: const Icon(Icons.swap_horiz, color: Color(0xFFBB86FC), size: 28),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
            elevation: isDark ? 0 : 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeader(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text, style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.w600, fontSize: 12));
  }

  Widget _buildAssetCard(BuildContext context, WidgetRef ref, AccountModel acc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    final bool isBank = acc.type == 'bank';
    final Color accentColor = Color(acc.colorCode);
    
    return Dismissible(
      key: Key(acc.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDeletion(context),
      onDismissed: (_) => ref.read(firestoreServiceProvider).deleteAccount(acc.id),
      background: _buildDeleteBackground(),
      child: Container(
        height: 120, 
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                right: -15, 
                bottom: -15, 
                child: Icon(
                  isBank ? Icons.account_balance : Icons.account_balance_wallet, 
                  color: accentColor.withOpacity(isDark ? 0.05 : 0.1), 
                  size: 110,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(acc.name, style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(acc.currentBalance, currency: currency), 
                            style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 28, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: isDark ? Colors.white24 : Colors.black26),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) async {
                        if (val == 'delete') {
                          final confirmed = await _confirmDeletion(context);
                          if (confirmed == true) {
                            ref.read(firestoreServiceProvider).deleteAccount(acc.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 12),
                              Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(child: Text("No accounts found", style: GoogleFonts.inter(color: isDark ? Colors.white10 : Colors.black12, fontSize: 14)));
  }

  Widget _buildFAB(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFBB86FC),
      shape: const StadiumBorder(), 
      onPressed: () => _showAddAccountDialog(context, ref),
      child: const Icon(Icons.add, color: Colors.black, size: 28),
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text("Delete Account?", style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to remove this account?", style: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14)),
          actions: [
            TextButton(child: Text("Cancel", style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38)), onPressed: () => Navigator.of(ctx).pop(false)),
            TextButton(child: Text("Delete", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)), onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.read(currencyProvider);
    String type = 'bank';

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('New Account', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(context, nameCtrl, 'Account Name'),
              const SizedBox(height: 16),
              _buildTextField(context, balanceCtrl, 'Initial Balance', isNumber: true, prefix: currency.symbol),
              const SizedBox(height: 16),
              _buildDropdown(context, (val) => type = val!, type),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Discard', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB86FC), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && balanceCtrl.text.isNotEmpty) {
                  ref.read(firestoreServiceProvider).addAccount(
                    name: nameCtrl.text,
                    initialBalance: double.parse(balanceCtrl.text),
                    type: type,
                    colorCode: type == 'bank' ? 0xFFBB86FC : 0xFF03DAC6, 
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Add Account', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController ctrl, String hint, {bool isNumber = false, String? prefix}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12),
        prefixText: prefix,
        prefixStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, Function(String?) onChanged, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: 'Account Type', 
        labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12)
      ),
      items: const [
        DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
        DropdownMenuItem(value: 'wallet', child: Text('Cash Wallet')),
      ],
      onChanged: onChanged,
    );
  }

  void _showTransferDialog(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final accounts = ref.read(accountsStreamProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.read(currencyProvider);

    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least two accounts to transfer.")));
      return;
    }

    String fromAccId = accounts.first.id;
    String toAccId = accounts.last.id;
    bool hasFee = false; // NEW: Track fee checkbox state

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text('Transfer Funds', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSimpleDropdown(context, 'From', fromAccId, accounts, (val) => setState(() => fromAccId = val!)),
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Icon(Icons.arrow_downward, color: isDark ? Colors.white12 : Colors.black12)),
                _buildSimpleDropdown(context, 'To', toAccId, accounts, (val) => setState(() => toAccId = val!)),
                const SizedBox(height: 16),
                _buildTextField(context, amountCtrl, 'Amount', isNumber: true, prefix: currency.symbol),
                const SizedBox(height: 16),
                
                // NEW: Fee Checkbox
                InkWell(
                  onTap: () => setState(() => hasFee = !hasFee),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: hasFee,
                          activeColor: const Color(0xFFBB86FC),
                          onChanged: (val) => setState(() => hasFee = val!),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Apply Transfer Fee', style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('${currency.symbol} 25.00 will be deducted', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  if (fromAccId == toAccId) return;
                  final amount = double.tryParse(amountCtrl.text) ?? 0;
                  if (amount <= 0) return;

                  await ref.read(firestoreServiceProvider).transferMoney(
                    fromAccountId: fromAccId,
                    toAccountId: toAccId,
                    amount: amount,
                    fee: hasFee ? 25.0 : 0.0,
                  );
                  Navigator.pop(context);
                },
                child: Text('Confirm', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleDropdown(BuildContext context, String label, String value, List<AccountModel> accounts, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12)
      ),
      items: accounts.map((acc) => DropdownMenuItem(
        value: acc.id, 
        child: Text(acc.name, style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black))
      )).toList(),
      onChanged: onChanged,
    );
  }
}