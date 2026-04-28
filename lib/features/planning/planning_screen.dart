import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../goals/goals_screen.dart';
import '../debts/debts_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/transaction_provider.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Strategy', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Wealth Planning', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'MY GOALS'),
              const SizedBox(height: 350, child: GoalsScreen()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: isDark ? Colors.white10 : Colors.black12, thickness: 1),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'OWES & OWED'),
              const SizedBox(height: 500, child: DebtsScreen()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBB86FC),
        shape: const StadiumBorder(),
        onPressed: () => _showActionSelector(context, ref),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  void _showActionSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
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
              Text('What are we tracking today?', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Row(
                children: [
                  _buildOptionCard(context, 'Saving Goal', Icons.stars_rounded, const Color(0xFF03DAC6), () {
                    Navigator.pop(context);
                    _showAddGoalDialog(context, ref);
                  }),
                  const SizedBox(width: 16),
                  _buildOptionCard(context, 'IOU Record', Icons.account_balance_wallet_rounded, const Color(0xFFBB86FC), () {
                    Navigator.pop(context);
                    _showDebtTypeSelector(context, ref);
                  }),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(title, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Set a New Goal', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(context, titleCtrl, 'What are you saving for?'),
              const SizedBox(height: 16),
              _buildDialogField(context, amountCtrl, 'How much do you need?', isNumber: true, prefix: 'Rs '),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03DAC6), shape: const StadiumBorder()),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  ref.read(firestoreServiceProvider).addGoal(
                    title: titleCtrl.text,
                    targetAmount: double.parse(amountCtrl.text),
                    deadline: DateTime.now().add(const Duration(days: 30)),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Create', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebtTypeSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Choose Record Type', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('I Borrowed Money', style: GoogleFonts.inter(color: const Color(0xFFCF6679))),
                onTap: () { Navigator.pop(context); _showAddDebtDialog(context, ref, 'borrowed'); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              ListTile(
                title: Text('I Lent Money', style: GoogleFonts.inter(color: const Color(0xFF03DAC6))),
                onTap: () { Navigator.pop(context); _showAddDebtDialog(context, ref, 'lent'); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, WidgetRef ref, String type) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(type == 'borrowed' ? 'Add Borrowed Amount' : 'Add Lent Amount', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(context, nameCtrl, 'Person\'s Name'),
              const SizedBox(height: 16),
              _buildDialogField(context, amountCtrl, 'Total Amount', isNumber: true, prefix: 'Rs '),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC), shape: const StadiumBorder()),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  ref.read(firestoreServiceProvider).addDebt(
                    personName: nameCtrl.text.trim(),
                    amount: double.parse(amountCtrl.text),
                    type: type,
                    dueDate: DateTime.now().add(const Duration(days: 14)),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(BuildContext context, TextEditingController ctrl, String hint, {bool isNumber = false, String? prefix}) {
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 11),
      ),
    );
  }
}