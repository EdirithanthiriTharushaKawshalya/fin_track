import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../core/utils/currency_formatter.dart';
import '../transactions/add_transaction_sheet.dart';
import 'transaction_provider.dart';
import 'widgets/balance_card.dart';
import '../../main.dart'; // To access themeProvider
import '../profile/profile_screen.dart'; // New Profile Screen import

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionStreamProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: transactionsAsync.when(
        data: (transactions) {
          final monthlyTransactions = transactions.where((t) {
            return t.date.year == selectedDate.year && t.date.month == selectedDate.month;
          }).toList();

          final Map<String, List<dynamic>> groupedTransactions = {};
          for (var t in monthlyTransactions) {
            final dateKey = DateFormat('EEEE, MMM d').format(t.date); 
            groupedTransactions.putIfAbsent(dateKey, () => []).add(t);
          }

          final dateKeys = groupedTransactions.keys.toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(context, ref, selectedDate),
                  const SizedBox(height: 24),
                  const BalanceCard(), 
                  const SizedBox(height: 32),
                  _buildSubHeader("Recent Transactions"),
                  const SizedBox(height: 16),
                  Expanded(
                    child: monthlyTransactions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            key: ValueKey(selectedDate),
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: dateKeys.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final date = dateKeys[index];
                              final items = groupedTransactions[date]!;
                              return _buildDateGroup(context, ref, date, items);
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
        error: (err, _) => Center(child: Text('Something went wrong', style: GoogleFonts.inter(color: Colors.redAccent))),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: GoogleFonts.inter(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(DateFormat('MMMM yyyy').format(selectedDate),
                style: GoogleFonts.spaceGrotesk(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          children: [
            _buildNavigationControls(ref, selectedDate, isDark),
            const SizedBox(width: 12),
            // SETTINGS ICON
            IconButton(
              onPressed: () => _showSettingsSheet(context, ref),
              icon: const Icon(Icons.settings_outlined, color: Color(0xFFBB86FC), size: 22),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationControls(WidgetRef ref, DateTime current, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFFBB86FC)), 
            onPressed: () => _updateMonth(ref, current, -1)
          ),
          Container(height: 20, width: 1, color: isDark ? Colors.white10 : Colors.black12),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFFBB86FC)), 
            onPressed: () => _updateMonth(ref, current, 1)
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212).withOpacity(0.9) : Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Text('Settings', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              
              // PROFILE ITEM - Now navigates to ProfileScreen
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'User Profile',
                subtitle: 'Manage your personal identity',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context); // Close the sheet
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const ProfileScreen())
                  );
                },
              ),
              const SizedBox(height: 8),

              // THEME TOGGLE
              _buildSettingsTile(
                icon: isDark ? Icons.dark_mode : Icons.light_mode,
                title: 'Appearance',
                subtitle: isDark ? 'Dark Theme Enabled' : 'Light Theme Enabled',
                isDark: isDark,
                trailing: Switch(
                  value: isDark,
                  activeColor: const Color(0xFFBB86FC),
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: const Color(0xFFBB86FC)),
        title: Text(title, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)),
        trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white10 : Colors.black12),
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Text(
        text,
        style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5),
      );
    });
  }

  Widget _buildDateGroup(BuildContext context, WidgetRef ref, String date, List<dynamic> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 24, bottom: 12),
          child: Text(date, style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        ...items.map((t) => _buildTransactionCard(context, ref, t)).toList(),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, dynamic t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final Color statusColor = isTransfer ? (isDark ? Colors.white54 : Colors.black45) : (isIncome ? const Color(0xFF03DAC6) : Colors.redAccent);

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => ref.read(firestoreServiceProvider).deleteTransaction(t),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(28)),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isTransfer ? Icons.sync_alt : (isIncome ? Icons.add : Icons.remove), color: statusColor, size: 20),
          ),
          title: Text(t.category, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(t.note ?? 'No description', style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black38, fontSize: 12)),
          trailing: Text(
            '${isTransfer ? '' : (isIncome ? '+' : '-')}${CurrencyFormatter.format(t.amount)}',
            style: GoogleFonts.spaceGrotesk(color: statusColor, fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFBB86FC),
      shape: const StadiumBorder(),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddTransactionSheet(),
      ),
      child: const Icon(Icons.add, color: Colors.black, size: 32),
    );
  }

  void _updateMonth(WidgetRef ref, DateTime current, int delta) {
    ref.read(selectedDateProvider.notifier).state = DateTime(current.year, current.month + delta, 1);
  }

  Widget _buildEmptyState() {
    return Center(child: Text("No transactions this month", style: GoogleFonts.inter(color: Colors.white10, fontSize: 14)));
  }
}