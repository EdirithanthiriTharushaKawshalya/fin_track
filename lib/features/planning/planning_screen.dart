import 'package:flutter/material.dart';
import '../goals/goals_screen.dart'; // We reuse the widget logic
import '../debts/debts_screen.dart'; // We reuse the widget logic

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Wealth Planning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: GOALS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MY GOALS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  // We would trigger the add dialog here properly in a full refactor,
                  // but for now, we just show the header.
                ],
              ),
            ),

            // We use a fixed height container to show the Goals list for now
            // In a real app, you might refactor GoalsScreen to not return a Scaffold.
            SizedBox(
              height: 300,
              child:
                  const GoalsScreen(), // Embedding the screen we made earlier
            ),

            const Divider(color: Colors.white10, thickness: 1, height: 40),

            // --- SECTION 2: DEBTS ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'DEBTS & LENDING',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            SizedBox(
              height: 400,
              child:
                  const DebtsScreen(), // Embedding the screen we made earlier
            ),
          ],
        ),
      ),
    );
  }
}
