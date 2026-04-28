import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../core/models/debt_model.dart';
import '../../core/utils/currency_formatter.dart';

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
        return Dismissible(
          key: Key(debt.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
          ),
          onDismissed: (_) => ref.read(firestoreServiceProvider).deleteDebt(debt.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
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
                Text(CurrencyFormatter.format(debt.amount), style: GoogleFonts.spaceGrotesk(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}