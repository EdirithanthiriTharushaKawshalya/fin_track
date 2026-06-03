import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/currency_provider.dart';
import '../transactions/add_transaction_sheet.dart';
import 'transaction_provider.dart';
import 'summary_hint_provider.dart';
import 'widgets/balance_card.dart';
import '../../main.dart'; // To access themeProvider
import '../profile/profile_screen.dart'; // To access ProfileScreen
import '../about/about_screen.dart'; // To access AboutScreen

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionStreamProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  const SizedBox(height: 16),
                  _buildDateStrip(context, ref, selectedDate),
                  const SizedBox(height: 20),
                  const BalanceCard(), 
                  const SizedBox(height: 32),
                  _buildSubHeader(context, "Recent Transactions"),
                  const SizedBox(height: 16),
                  Expanded(
                    child: monthlyTransactions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            key: ValueKey(selectedDate),
                            padding: const EdgeInsets.only(bottom: 180),
                            itemCount: dateKeys.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final date = dateKeys[index];
                              final items = groupedTransactions[date]!;
                              return _buildDateGroup(context, ref, date, items, index == 0);
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
            IconButton(
              onPressed: () => _showSettingsSheet(context),
              icon: const Icon(Icons.settings_outlined, color: Color(0xFFBB86FC), size: 22),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                elevation: isDark ? 0 : 2,
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
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final themeMode = ref.watch(themeProvider);
          final isDark = themeMode == ThemeMode.dark;

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 24),
                  Text('Settings', 
                    style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),

                  _buildSettingsTile(
                    icon: Icons.person_outline,
                    title: 'User Profile',
                    subtitle: 'Manage your personal identity',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context); 
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const ProfileScreen())
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildSettingsTile(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    title: 'Appearance',
                    subtitle: isDark ? 'Dark Theme Enabled' : 'Light Theme Enabled',
                    isDark: isDark,
                    trailing: Switch(
                      value: isDark,
                      activeColor: const Color(0xFFBB86FC),
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About FinTrack',
                    subtitle: 'App version and developer info',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
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
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
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

  Widget _buildSubHeader(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5),
    );
  }

  Widget _buildDateGroup(BuildContext context, WidgetRef ref, String date, List<dynamic> items, bool isFirst) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showHint = ref.watch(summaryHintProvider) && isFirst;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            ref.read(summaryHintProvider.notifier).dismissHint();
            _showDailySummary(context, ref, date, items);
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 24, bottom: 12),
            child: Row(
              children: [
                Text(date, style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (showHint)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.blueAccent : Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insights_rounded, size: 10, color: isDark ? Colors.blueAccent : Colors.blue),
                        const SizedBox(width: 4),
                        Text('TAP FOR SUMMARY', style: GoogleFonts.inter(color: isDark ? Colors.blueAccent : Colors.blue, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
                  )
                else
                  Icon(Icons.insights_rounded, size: 12, color: isDark ? Colors.white12 : Colors.black12),
              ],
            ),
          ),
        ),
        ...items.map((t) => _buildTransactionCard(context, ref, t)).toList(),
      ],
    );
  }


  void _showDailySummary(BuildContext context, WidgetRef ref, String date, List<dynamic> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.read(currencyProvider);

    double totalIncome = 0;
    double totalExpense = 0;
    double totalTransfer = 0;

    for (var t in items) {
      if (t.type == 'income') totalIncome += t.amount;
      else if (t.type == 'expense') totalExpense += t.amount;
      else if (t.type == 'transfer') totalTransfer += t.amount;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 32),
            Text('Daily Summary', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            Text(date, style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontSize: 14)),
            const SizedBox(height: 32),

            _buildSummaryRow(
              label: 'Total Income',
              amount: totalIncome,
              color: const Color(0xFF03DAC6),
              icon: Icons.add_circle_outline_rounded,
              isDark: isDark,
              currency: currency,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              label: 'Total Expenses',
              amount: totalExpense,
              color: Colors.redAccent,
              icon: Icons.remove_circle_outline_rounded,
              isDark: isDark,
              currency: currency,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              label: 'Internal Transfers',
              amount: totalTransfer,
              color: isDark ? Colors.white54 : Colors.black54,
              icon: Icons.sync_alt_rounded,
              isDark: isDark,
              currency: currency,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({required String label, required double amount, required Color color, required IconData icon, required bool isDark, required dynamic currency}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            CurrencyFormatter.format(amount, currency: currency),
            style: GoogleFonts.spaceGrotesk(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, dynamic t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    final isIncome = t.type == 'income' || t.type == 'debt_borrowed' || t.type == 'debt_repayment_received';
    final isTransfer = t.type == 'transfer';
    final isDebt = t.type.startsWith('debt_');
    final hasFee = isTransfer && (t.fee ?? 0) > 0;
    
    // Determine color
    Color statusColor;
    if (isTransfer) {
      statusColor = hasFee ? Colors.orangeAccent : (isDark ? Colors.white54 : Colors.black45);
    } else if (isDebt) {
      statusColor = const Color(0xFFBB86FC); // Use primary purple for all debt-related
    } else {
      statusColor = isIncome ? const Color(0xFF03DAC6) : Colors.redAccent;
    }

    // Determine Icon
    IconData iconData;
    if (isTransfer) {
      iconData = Icons.sync_alt;
    } else if (t.type == 'debt_lent') {
      iconData = Icons.arrow_outward_rounded;
    } else if (t.type == 'debt_borrowed') {
      iconData = Icons.arrow_downward_rounded;
    } else if (t.type == 'debt_repayment_received') {
      iconData = Icons.assignment_returned_rounded;
    } else if (t.type == 'debt_repayment_paid') {
      iconData = Icons.assignment_turned_in_rounded;
    } else {
      iconData = isIncome ? Icons.add : Icons.remove;
    }

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirmation(context),
      onDismissed: (direction) => ref.read(firestoreServiceProvider).deleteTransaction(t),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(28)),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      child: GestureDetector(
        onTap: () => _showTransactionDetails(context, ref, t),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(iconData, color: statusColor, size: 20),
            ),
            title: Text(t.category, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(t.note ?? 'No description', style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black38, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isTransfer ? '' : (isIncome ? '+' : '-')}${CurrencyFormatter.format(t.amount, currency: currency)}',
                  style: GoogleFonts.spaceGrotesk(color: isDebt ? (isIncome ? const Color(0xFF03DAC6) : Colors.redAccent) : statusColor, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                if (hasFee)
                  Text(
                    '+ Fee: ${CurrencyFormatter.format(t.fee, currency: currency)}',
                    style: GoogleFonts.inter(color: Colors.redAccent.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, WidgetRef ref, dynamic t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.read(currencyProvider);
    final isIncome = t.type == 'income' || t.type == 'debt_borrowed' || t.type == 'debt_repayment_received';
    final isTransfer = t.type == 'transfer';
    final isDebt = t.type.startsWith('debt_');

    Color statusColor;
    if (isTransfer) {
      statusColor = (isDark ? Colors.white54 : Colors.black54);
    } else if (isDebt) {
      statusColor = const Color(0xFFBB86FC);
    } else {
      statusColor = isIncome ? const Color(0xFF03DAC6) : Colors.redAccent;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 32),
            Text(t.category, style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text(
              '${isTransfer ? 'Transfer' : (isDebt ? 'Debt Transaction' : (isIncome ? 'Income' : 'Expense'))} • ${DateFormat('MMM dd, yyyy').format(t.date)}',
              style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    '${isTransfer ? '' : (isIncome ? '+' : '-')}${CurrencyFormatter.format(t.amount, currency: currency)}',
                    style: GoogleFonts.spaceGrotesk(color: isDebt ? (isIncome ? const Color(0xFF03DAC6) : Colors.redAccent) : statusColor, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  if (isTransfer && (t.fee ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Transfer Fee: ${CurrencyFormatter.format(t.fee, currency: currency)}',
                        style: GoogleFonts.inter(color: Colors.redAccent.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            if (t.note != null && t.note!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                t.note!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16),
              ),
            ],
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(firestoreServiceProvider).deleteTransaction(t);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
                if (!isDebt) ...[ // Disable editing for debt transactions as they are linked to debts
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddTransactionSheet(transaction: t),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBB86FC),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Delete Transaction?', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to remove this record? This action cannot be undone.', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: const StadiumBorder()),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: FloatingActionButton(
        backgroundColor: const Color(0xFFBB86FC),
        shape: const StadiumBorder(),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AddTransactionSheet(),
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }

  void _updateMonth(WidgetRef ref, DateTime current, int delta) {
    ref.read(selectedDateProvider.notifier).state = DateTime(current.year, current.month + delta, 1);
  }

  Widget _buildEmptyState() {
    return Center(child: Text("No transactions this month", style: GoogleFonts.inter(color: Colors.white10, fontSize: 14)));
  }

  Widget _buildDateStrip(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    // Find Monday of the current week containing selectedDate
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final daysOfWeek = List.generate(7, (index) => monday.add(Duration(days: index)));
    final now = DateTime.now();

    return Row(
      children: daysOfWeek.map((day) {
        // Only highlight if it is the actual real today
        final isToday = day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;
        final dayLabel = DateFormat('E').format(day).toUpperCase(); // e.g., MON
        final dateLabel = day.day.toString(); // e.g., 3

        return _buildDateCapsule(
          dayLabel: dayLabel,
          dateLabel: dateLabel,
          isSelected: isToday,
          context: context,
        );
      }).toList(),
    );
  }

  Widget _buildDateCapsule({
    required String dayLabel,
    required String dateLabel,
    required bool isSelected,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final Color selectedBg = primaryColor;
    final Color unselectedBg = isDark ? const Color(0xFF1E1E1E) : Colors.black.withOpacity(0.04);

    final Color selectedDot = Colors.white;
    final Color unselectedDot = isDark ? Colors.white30 : Colors.black26;

    final Color selectedDayColor = Colors.white.withOpacity(0.75);
    final Color unselectedDayColor = isDark ? Colors.white38 : Colors.black45;

    final Color selectedDateColor = Colors.white;
    final Color unselectedDateColor = isDark ? Colors.white : Colors.black87;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? selectedBg
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Capsule dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? selectedDot : unselectedDot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            // Day of the week (e.g. MON)
            Text(
              dayLabel,
              style: GoogleFonts.inter(
                color: isSelected ? selectedDayColor : unselectedDayColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            // Date number (e.g. 3)
            Text(
              dateLabel,
              style: GoogleFonts.spaceGrotesk(
                color: isSelected ? selectedDateColor : unselectedDateColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
