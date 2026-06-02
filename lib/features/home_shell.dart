import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/widgets/grid_background.dart';
import 'dashboard/dashboard_screen.dart';
import 'accounts/accounts_screen.dart';
import 'planning/wealth_planning_screen.dart';
import 'analytics/analytics_screen.dart';
import 'debts/debts_screen.dart';

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
    const WealthPlanningScreen(),
    const DebtsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
        body: GridBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _screens[_selectedIndex],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          final isSelected = _selectedIndex == index;
                          
                          // Determine icon and label
                          final IconData icon;
                          final IconData selectedIcon;
                          final String label;
                          
                          switch (index) {
                            case 0:
                              icon = Icons.home_outlined;
                              selectedIcon = Icons.home;
                              label = 'Home';
                              break;
                            case 1:
                              icon = Icons.receipt_long_outlined;
                              selectedIcon = Icons.receipt_long;
                              label = 'Assets';
                              break;
                            case 2:
                              icon = Icons.pie_chart_outline;
                              selectedIcon = Icons.pie_chart;
                              label = 'Analytics';
                              break;
                            case 3:
                              icon = Icons.credit_card_outlined;
                              selectedIcon = Icons.credit_card;
                              label = 'Plan';
                              break;
                            case 4:
                            default:
                              icon = Icons.person_outline;
                              selectedIcon = Icons.person;
                              label = 'Debts';
                              break;
                          }

                          return GestureDetector(
                            onTap: () => setState(() => _selectedIndex = index),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 16 : 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.12) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? selectedIcon : icon,
                                    color: isSelected ? Colors.white : Colors.white38,
                                    size: 24,
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    child: Row(
                                      children: [
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            label,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
