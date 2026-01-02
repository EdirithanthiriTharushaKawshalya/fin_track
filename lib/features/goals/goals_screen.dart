import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/goal_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/currency_formatter.dart'; // Import the formatter

// Create a provider specifically for goals
final goalsStreamProvider = StreamProvider<List<GoalModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getGoals();
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Target Lock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(context, ref),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Text(
                "No active targets.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final progress = (goal.savedAmount / goal.targetAmount).clamp(
                0.0,
                1.0,
              );
              final percent = (progress * 100).toStringAsFixed(0);

              return Dismissible(
                key: Key(goal.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.withOpacity(0.2),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                onDismissed: (_) =>
                    ref.read(firestoreServiceProvider).deleteGoal(goal.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF03DAC6).withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            goal.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              color: Color(0xFF03DAC6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Target: ${DateFormat('MMM d, y').format(goal.deadline)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Futuristic Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          color: const Color(0xFF03DAC6),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // UPDATED: Using CurrencyFormatter
                          Text(
                            '${CurrencyFormatter.format(goal.savedAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF03DAC6),
                              foregroundColor: Colors.black,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () =>
                                _showDepositDialog(context, ref, goal),
                            child: const Text('DEPOSIT'),
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
    );
  }

  // Dialog to Add New Goal
  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('New Target', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Goal Name'),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              // UPDATED: Added prefixText for input
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: 'Rs ',
                prefixStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              'CREATE',
              style: TextStyle(color: Color(0xFF03DAC6)),
            ),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                ref
                    .read(firestoreServiceProvider)
                    .addGoal(
                      title: titleCtrl.text,
                      targetAmount: double.parse(amountCtrl.text),
                      deadline: DateTime.now().add(
                        const Duration(days: 30),
                      ), // Default 30 days
                    );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  // Dialog to Add Money to Goal
  void _showDepositDialog(BuildContext context, WidgetRef ref, GoalModel goal) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Funds', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          // UPDATED: Added prefixText for input
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: 'Rs ',
            prefixStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'DEPOSIT',
              style: TextStyle(color: Color(0xFF03DAC6)),
            ),
            onPressed: () {
              final added = double.tryParse(amountCtrl.text) ?? 0;
              ref
                  .read(firestoreServiceProvider)
                  .updateGoalProgress(goal.id, goal.savedAmount + added);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
