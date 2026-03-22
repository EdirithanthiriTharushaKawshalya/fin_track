import 'package:fin_track/features/dashboard/transaction_provider.dart';
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
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context, ref),
              const SizedBox(height: 32),
              _buildSubHeader("Your Assets"),
              const SizedBox(height: 16),
              Expanded(
                child: accountsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
                  error: (err, _) => Center(child: Text('Error loading accounts', style: GoogleFonts.inter(color: Colors.redAccent))),
                  data: (accounts) {
                    if (accounts.isEmpty) return _buildEmptyState();
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('My Accounts', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          ],
        ),
        IconButton(
          onPressed: () => _showTransferDialog(context, ref),
          icon: const Icon(Icons.swap_horiz, color: Color(0xFFBB86FC), size: 28),
          // Increased border radius for a rounder look
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.03), 
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeader(String text) {
    return Text(text, style: GoogleFonts.inter(color: Colors.white24, fontWeight: FontWeight.w600, fontSize: 12));
  }

  Widget _buildAssetCard(BuildContext context, WidgetRef ref, AccountModel acc) {
    final bool isBank = acc.type == 'bank';
    final Color accentColor = Color(acc.colorCode);
    
    return Dismissible(
      key: Key(acc.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDeletion(context),
      onDismissed: (_) => ref.read(firestoreServiceProvider).deleteAccount(acc.id),
      background: _buildDeleteBackground(),
      child: Container(
        // Set a fixed height so all cards are the same size
        height: 120, 
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withOpacity(0.15), accentColor.withOpacity(0.03)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28), // Matches the modern rounded aesthetic
          border: Border.all(color: accentColor.withOpacity(0.1)),
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
                  color: accentColor.withOpacity(0.05), 
                  size: 110,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Centering content within the fixed height
                  children: [
                    Text(acc.name, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(acc.currentBalance), 
                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
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

  Widget _buildEmptyState() {
    return Center(child: Text("No accounts found", style: GoogleFonts.inter(color: Colors.white10, fontSize: 14)));
  }

  Widget _buildFAB(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFBB86FC),
      // Fully rounded FAB
      shape: const StadiumBorder(), 
      onPressed: () => _showAddAccountDialog(context, ref),
      child: const Icon(Icons.add, color: Colors.black, size: 28),
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text("Delete Account?", style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to remove this account?", style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
          actions: [
            TextButton(child: Text("Cancel", style: GoogleFonts.inter(color: Colors.white38)), onPressed: () => Navigator.of(ctx).pop(false)),
            TextButton(child: Text("Delete", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)), onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String type = 'bank';

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('New Account', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameCtrl, 'Account Name'),
              const SizedBox(height: 16),
              _buildTextField(balanceCtrl, 'Initial Balance', isNumber: true, prefix: 'Rs '),
              const SizedBox(height: 16),
              _buildDropdown((val) => type = val!, type),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Discard', style: GoogleFonts.inter(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB86FC), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Pill-shaped button
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

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isNumber = false, String? prefix}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
        prefixText: prefix,
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
      ),
    );
  }

  Widget _buildDropdown(Function(String?) onChanged, String value) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF121212),
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(labelText: 'Account Type', labelStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
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

    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least two accounts to transfer.")));
      return;
    }

    String fromAccId = accounts.first.id;
    String toAccId = accounts.last.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF121212),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text('Transfer Funds', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSimpleDropdown('From', fromAccId, accounts, (val) => setState(() => fromAccId = val!)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Icon(Icons.arrow_downward, color: Colors.white12)),
                _buildSimpleDropdown('To', toAccId, accounts, (val) => setState(() => toAccId = val!)),
                const SizedBox(height: 16),
                _buildTextField(amountCtrl, 'Amount', isNumber: true, prefix: 'Rs '),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  if (fromAccId == toAccId) return;
                  await ref.read(firestoreServiceProvider).transferMoney(
                    fromAccountId: fromAccId,
                    toAccountId: toAccId,
                    amount: double.tryParse(amountCtrl.text) ?? 0,
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

  Widget _buildSimpleDropdown(String label, String value, List<AccountModel> accounts, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF121212),
      decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
      items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)))).toList(),
      onChanged: onChanged,
    );
  }
}