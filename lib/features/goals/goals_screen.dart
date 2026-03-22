import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../core/models/goal_model.dart';
import '../../core/utils/currency_formatter.dart';

final goalsStreamProvider = StreamProvider<List<GoalModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getGoals();
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
          error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
          data: (goals) {
            if (goals.isEmpty) {
              return Center(
                child: Text("No active targets.", style: GoogleFonts.inter(color: Colors.white10)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: goals.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
                final percent = (progress * 100).toStringAsFixed(0);

                return Dismissible(
                  key: Key(goal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  onDismissed: (_) => ref.read(firestoreServiceProvider).deleteGoal(goal.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF03DAC6).withOpacity(0.15), const Color(0xFF03DAC6).withOpacity(0.03)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF03DAC6).withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(goal.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('$percent%', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF03DAC6), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Target: ${DateFormat('MMM d, y').format(goal.deadline)}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            color: const Color(0xFF03DAC6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${CurrencyFormatter.format(goal.savedAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                              style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF03DAC6),
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              onPressed: () => _showDepositDialog(context, ref, goal),
                              child: Text('DEPOSIT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context, WidgetRef ref, GoalModel goal) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Add Funds', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
              prefixText: 'Rs ',
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF03DAC6))),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03DAC6), shape: const StadiumBorder()),
              onPressed: () {
                final added = double.tryParse(amountCtrl.text) ?? 0;
                ref.read(firestoreServiceProvider).updateGoalProgress(goal.id, goal.savedAmount + added);
                Navigator.pop(context);
              },
              child: Text('Deposit', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}