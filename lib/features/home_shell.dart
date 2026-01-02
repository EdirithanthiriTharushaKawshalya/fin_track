import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';
import 'debts/debts_screen.dart';
import 'accounts/accounts_screen.dart';
import 'planning/planning_screen.dart';
import 'analytics/analytics_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  // List of screens to switch between
  final List<Widget> _screens = [
    const DashboardScreen(), // Tab 0
    const AccountsScreen(), // Tab 1 (New)
    const AnalyticsScreen(), // Tab 2 (New)
    const PlanningScreen(), // Tab 3 (Unified Goals/Debts)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFBB86FC).withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFF1E1E1E),
          height: 60,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFFBB86FC)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white54,
              ),
              selectedIcon: Icon(
                Icons.account_balance_wallet,
                color: Color(0xFFBB86FC),
              ),
              label: 'Assets',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline, color: Colors.white54),
              selectedIcon: Icon(Icons.pie_chart, color: Color(0xFFBB86FC)),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.map, color: Color(0xFFBB86FC)),
              label: 'Plan',
            ),
          ],
        ),
      ),
    );
  }
}
