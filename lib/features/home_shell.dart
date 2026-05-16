import 'package:flutter/material.dart';
import '../core/widgets/grid_background.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: GridBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _screens[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.1), 
                          blurRadius: 20, 
                          offset: const Offset(0, -5)
                        )
                      ],
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
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
                            TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        child: NavigationBar(
                          backgroundColor: Colors.transparent,
                          height: 70,
                          elevation: 0,
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                          destinations: [
                            NavigationDestination(
                              icon: Icon(Icons.dashboard_outlined, color: isDark ? Colors.white54 : Colors.black45),
                              selectedIcon: const Icon(Icons.dashboard, color: Color(0xFFBB86FC)),
                              label: 'Home',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.account_balance_wallet_outlined, color: isDark ? Colors.white54 : Colors.black45),
                              selectedIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFFBB86FC)),
                              label: 'Assets',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.pie_chart_outline, color: isDark ? Colors.white54 : Colors.black45),
                              selectedIcon: const Icon(Icons.pie_chart, color: Color(0xFFBB86FC)),
                              label: 'Analytics',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.map_outlined, color: isDark ? Colors.white54 : Colors.black45),
                              selectedIcon: const Icon(Icons.map, color: Color(0xFFBB86FC)),
                              label: 'Plan',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
