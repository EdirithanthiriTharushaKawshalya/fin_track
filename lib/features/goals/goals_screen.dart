import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:fin_track/core/services/currency_provider.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
          error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
          data: (goals) {
            if (goals.isEmpty) {
              return Center(child: Text("No active targets.", style: GoogleFonts.inter(color: isDark ? Colors.white10 : Colors.black12)));
            }

            // Sort logic: Incomplete first (newest first), then completed (newest first)
            final sortedGoals = List<GoalModel>.from(goals)..sort((a, b) {
              final aDone = a.savedAmount >= a.targetAmount;
              final bDone = b.savedAmount >= b.targetAmount;
              
              if (aDone != bDone) {
                return aDone ? 1 : -1; // Incomplete before complete
              }
              
              // Both are same status, sort by createdAt descending
              final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: sortedGoals.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final goal = sortedGoals[index];
                final progress = (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);
                final percent = (progress * 100).toStringAsFixed(0);
                final isCompleted = goal.savedAmount >= goal.targetAmount;

                return Dismissible(
                  key: Key(goal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(28)),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  onDismissed: (_) => ref.read(firestoreServiceProvider).deleteGoal(goal.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isCompleted ? Colors.greenAccent : const Color(0xFF03DAC6)).withOpacity(0.15),
                            (isDark ? Colors.white : Colors.black).withOpacity(0.02)
                          ],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(goal.title, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                    if (isCompleted) 
                                      Text('COMPLETED', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text('$percent%', style: GoogleFonts.spaceGrotesk(color: isCompleted ? Colors.greenAccent : const Color(0xFF03DAC6), fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: isDark ? Colors.white24 : Colors.black26, size: 20),
                                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    onSelected: (val) {
                                      if (val == 'delete') {
                                        ref.read(firestoreServiceProvider).deleteGoal(goal.id);
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
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Target: ${DateFormat('MMM d, y').format(goal.deadline)}', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                              color: isCompleted ? Colors.greenAccent : const Color(0xFF03DAC6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${CurrencyFormatter.format(goal.savedAmount, currency: currency)} / ${CurrencyFormatter.format(goal.targetAmount, currency: currency)}',
                                style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              if (!isCompleted)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF03DAC6),
                                    foregroundColor: Colors.black,
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showDepositDialog(context, ref, goal),
                                  child: Text('DEPOSIT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              else
                                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                            ],
                          ),
                        ],
                      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.read(currencyProvider);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Add Funds', style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12),
              prefixText: currency.symbol,
              prefixStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF03DAC6))),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
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
