import 'package:flutter/material.dart';
import '../dashboard/widgets/spending_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // We can reuse the chart widget we built
            SpendingChart(),

            SizedBox(height: 24),
            Text(
              "More insights coming soon...",
              style: TextStyle(color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}
