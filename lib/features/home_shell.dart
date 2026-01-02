import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  // List of screens to switch between
  final List<Widget> _screens = [
    const DashboardScreen(),
    const GoalsScreen(),
    const Scaffold(
      body: Center(
        child: Text("Debts Coming Soon", style: TextStyle(color: Colors.white)),
      ),
    ),
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
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.flag, color: Color(0xFFBB86FC)),
              label: 'Goals',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: Colors.white54),
              selectedIcon: Icon(Icons.people, color: Color(0xFFBB86FC)),
              label: 'Debts',
            ),
          ],
        ),
      ),
    );
  }
}
