import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
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

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AccountsScreen(),
    const AnalyticsScreen(),
    const PlanningScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matching the dashboard background color for seamless blending
      backgroundColor: const Color(0xFF080808), 
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        // Adding a slight top border to define the edge against the dashboard
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: const Color(0xFFBB86FC).withOpacity(0.2),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: const Color(0xFF1E1E1E),
              height: 70,
              elevation: 0,
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
                  icon: Icon(Icons.account_balance_wallet_outlined, color: Colors.white54),
                  selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFFBB86FC)),
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
        ),
      ),
    );
  }
}