import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:fin_track/core/services/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../core/models/debt_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../accounts/accounts_screen.dart'; // Import this

final debtsStreamProvider = StreamProvider<List<DebtModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getDebts();
});

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Owes & Owed', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 24)),
            ),
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: _tabController.index == 0 ? const Color(0xFFCF6679).withOpacity(0.2) : const Color(0xFF03DAC6).withOpacity(0.2),
                  ),
                  labelColor: _tabController.index == 0 ? const Color(0xFFCF6679) : const Color(0xFF03DAC6),
                  unselectedLabelColor: isDark ? Colors.white24 : Colors.black26,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [Tab(text: 'I OWE'), Tab(text: 'OWED TO ME')],
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            Expanded(
              child: debtsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
                error: (err, _) => Center(child: Text('Couldn\'t load records', style: const TextStyle(color: Colors.redAccent))),
                data: (allDebts) {
                  final borrowed = allDebts.where((d) => d.type == 'borrowed').toList();
                  final lent = allDebts.where((d) => d.type == 'lent').toList();
                  return TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [_buildDebtList(context, borrowed, isBorrowed: true), _buildDebtList(context, lent, isBorrowed: false)],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtList(BuildContext context, List<DebtModel> debts, {required bool isBorrowed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    if (debts.isEmpty) {
      return Center(child: Text("All settled up! No records here.", style: GoogleFonts.inter(color: isDark ? Colors.white10 : Colors.black12)));
    }

    final Color color = isBorrowed ? const Color(0xFFCF6679) : const Color(0xFF03DAC6);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: debts.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final debt = debts[index];
        final progress = debt.amount > 0 ? debt.paidAmount / debt.amount : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text(debt.personName.isNotEmpty ? debt.personName[0].toUpperCase() : '?', style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(debt.personName, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(isBorrowed ? 'Due to pay: ${DateFormat('MMM d').format(debt.dueDate)}' : 'Expecting by: ${DateFormat('MMM d').format(debt.dueDate)}', style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black38, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(
                          debt.paidAmount > 0 ? debt.remainingAmount : debt.amount,
                          currency: currency,
                        ),
                        style: GoogleFonts.spaceGrotesk(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (debt.paidAmount > 0)
                        Text(
                          'Original: ${CurrencyFormatter.format(debt.amount, currency: currency)}',
                          style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black38, fontSize: 10),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (debt.paidAmount > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteDebt(context, debt),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmSettleDebt(context, debt),
                      icon: Icon(isBorrowed ? Icons.payments_outlined : Icons.account_balance_wallet_outlined, size: 18),
                      label: Text(isBorrowed ? 'Pay' : 'Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.withOpacity(0.1),
                        foregroundColor: color,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDeleteDebt(BuildContext context, DebtModel debt) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Delete Record?', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to remove this record? This will also delete all associated transactions and reverse their impact on your account balances.', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: const StadiumBorder()),
              onPressed: () {
                ref.read(firestoreServiceProvider).deleteDebt(debt);
                Navigator.pop(context, true);
              },
              child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmSettleDebt(BuildContext context, DebtModel debt) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.read(currencyProvider);
    String? selectedAccountId = debt.accountId;
    final amountController = TextEditingController(text: debt.remainingAmount.toStringAsFixed(0));
    String? errorText;

    return await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Consumer(
          builder: (context, ref, child) {
            final accounts = ref.watch(accountsStreamProvider).value ?? [];
            if (selectedAccountId == null && accounts.isNotEmpty) {
              selectedAccountId = accounts.first.id;
            }
            
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                title: Text(debt.type == 'lent' ? 'Record Repayment' : 'Make Payment', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('You can record a partial payment or full settlement.', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        if (errorText != null) setState(() => errorText = null);
                      },
                      style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Amount to Pay',
                        labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12),
                        prefixText: currency.symbol,
                        errorText: errorText,
                        errorStyle: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy_all, size: 20),
                          onPressed: () {
                            amountController.text = debt.remainingAmount.toStringAsFixed(0);
                            setState(() => errorText = null);
                          },
                          tooltip: 'Full Amount',
                        ),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: debt.type == 'lent' ? 'Account Receiving Money' : 'Account Paying From',
                        labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
                      ),
                      items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text(acc.name))).toList(),
                      onChanged: (val) => selectedAccountId = val,
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03DAC6), shape: const StadiumBorder()),
                    onPressed: () {
                      final payAmount = double.tryParse(amountController.text) ?? 0.0;
                      if (payAmount > debt.remainingAmount) {
                        setState(() {
                          errorText = 'Max ${currency.symbol}${debt.remainingAmount.toStringAsFixed(0)}';
                        });
                        return;
                      }
                      if (selectedAccountId != null && payAmount > 0) {
                        ref.read(firestoreServiceProvider).recordDebtPayment(
                          debt: debt,
                          accountId: selectedAccountId!,
                          paymentAmount: payAmount,
                        );
                        Navigator.pop(context, true);
                      }
                    },
                    child: Text('Confirm', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
