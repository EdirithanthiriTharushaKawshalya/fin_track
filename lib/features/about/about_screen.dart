import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/grid_background.dart';
import 'dart:ui';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFBB86FC);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GridBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              children: [
            // Background Aesthetic Glow (BoxShadow instead of BackdropFilter)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(isDark ? 0.05 : 0.08),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    expandedHeight: 120,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('FinTrack', 
                        style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroSection(isDark),
                          const SizedBox(height: 40),
                          _buildSectionHeader('CORE MISSION', isDark),
                          const SizedBox(height: 16),
                          _buildMissionCard(isDark),
                          const SizedBox(height: 40),
                          _buildSectionHeader('INNOVATIVE FEATURES', isDark),
                          const SizedBox(height: 16),
                          _buildFeatureGrid(isDark),
                          const SizedBox(height: 60),
                          _buildDeveloperCard(isDark),
                          const SizedBox(height: 40),
                          Center(
                            child: Text('Version 3.0.0 (Stable)', 
                              style: GoogleFonts.inter(color: isDark ? Colors.white10 : Colors.black12, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildHeroSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFBB86FC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFBB86FC).withOpacity(0.2)),
          ),
          child: Text('NEXT-GEN FINANCE', 
            style: GoogleFonts.inter(color: const Color(0xFFBB86FC), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 16),
        Text(
          'Redefining how you\nvisualize wealth.',
          style: GoogleFonts.spaceGrotesk(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: isDark ? Colors.white24 : Colors.black26,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildMissionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Text(
        'FinTrack was built to bridge the gap between complex financial data and intuitive human interaction. Our goal is to empower users with a "Financial Command Center" that feels futuristic, yet remains perfectly practical for daily use.',
        style: GoogleFonts.inter(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(bool isDark) {
    final features = [
      {
        'icon': Icons.auto_graph_rounded,
        'title': 'Intelligent Insights & Analytics',
        'desc': 'Interactive data visualization that lets you dive deep into your spending patterns. Track your daily, weekly, and monthly trends with beautiful, easy-to-understand charts that help you identify where your money is going and how to optimize your budget.',
        'color': const Color(0xFF03DAC6),
      },
      {
        'icon': Icons.account_balance_rounded,
        'title': 'Multi-Account Sync & Management',
        'desc': 'Manage cash, bank accounts, and investments in one unified "Master Balance" view. Effortlessly transfer funds between accounts and keep track of your entire financial portfolio without switching between different apps.',
        'color': const Color(0xFFBB86FC),
      },
      {
        'icon': Icons.track_changes_rounded,
        'title': 'Strategic Goals & Planning',
        'desc': 'Advanced goal tracking with real-time progress calculations and deadline monitoring. Set saving targets for vacations, emergencies, or large purchases, and watch your progress grow with intelligent forecasts.',
        'color': const Color(0xFFFFB74D),
      },
      {
        'icon': Icons.handshake_rounded,
        'title': 'IOU Intelligence',
        'desc': 'A sophisticated "Owes & Owed" system to manage personal debts and lending. Keep track of who owes you money and who you owe, complete with transaction history and settlement features.',
        'color': const Color(0xFFCF6679),
      },
    ];

    return Column(
      children: features.map((f) {
        final Color color = f['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(f['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['title'] as String, 
                      style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(f['desc'] as String, 
                      style: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeveloperCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFBB86FC).withOpacity(0.2), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFBB86FC).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBB86FC), width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFBB86FC).withOpacity(0.1),
              child: const Icon(Icons.person_rounded, color: Color(0xFFBB86FC), size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tharusha Kawshalya', 
            style: GoogleFonts.spaceGrotesk(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Lead Architect & UI Designer', 
            style: GoogleFonts.inter(color: const Color(0xFFBB86FC), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 24),
          Text(
            'Crafting digital experiences that merge high-end aesthetics with powerful engineering.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
