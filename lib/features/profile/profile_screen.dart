import 'package:firebase_auth/firebase_auth.dart';
import 'package:fin_track/features/dashboard/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Logic to handle sensitive password updates
  Future<void> _updateAccessKey(
      BuildContext context, String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Key successfully rotated.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF03DAC6),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Authentication Failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Logic to handle CSV Export
  void _handleExport() {
    final transactions = ref.read(transactionStreamProvider).value ?? [];
    
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records available to export.")),
      );
      return;
    }

    // Professional Note: Once you add 'csv' and 'share_plus' to pubspec.yaml, 
    // you can call the ExportService here. For now, we show a status update.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing CSV document...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, 
            color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Identity Control', 
          style: GoogleFonts.spaceGrotesk(
            color: isDark ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold, 
            fontSize: 18
          )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileCard(context, user, isDark),
            const SizedBox(height: 32),
            
            _buildSectionLabel('SECURITY PROTOCOLS', isDark),
            const SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.shield_outlined,
              title: 'Change Access Key',
              subtitle: 'Rotate your login credentials',
              isDark: isDark,
              onTap: () => _showUpdatePasswordDialog(context),
            ),
            
            const SizedBox(height: 32),
            
            _buildSectionLabel('SYSTEM ACTIONS', isDark),
            const SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.file_download_outlined,
              title: 'Export Financial Data',
              subtitle: 'Generate CSV of all records',
              isDark: isDark,
              onTap: _handleExport,
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: Icons.logout_rounded,
              title: 'Terminate Session',
              subtitle: 'Securely sign out',
              color: const Color(0xFFCF6679),
              isDark: isDark,
              onTap: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, User? user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFBB86FC).withOpacity(0.15),
            isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFBB86FC).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBB86FC).withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFBB86FC).withOpacity(0.1),
              child: const Icon(Icons.person_rounded, size: 40, color: Color(0xFFBB86FC)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user?.email?.split('@')[0].toUpperCase() ?? 'USER_NULL',
            style: GoogleFonts.spaceGrotesk(
              color: isDark ? Colors.white : Colors.black, 
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'Unknown Identity',
            style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white12 : Colors.black26,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Color? color,
    required VoidCallback onTap,
  }) {
    final accentColor = color ?? const Color(0xFFBB86FC);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black38, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white10 : Colors.black12, size: 18),
      ),
    );
  }

  void _showUpdatePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Rotate Access Key', 
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(currentCtrl, 'Current Access Key', isDark, isPassword: true),
              const SizedBox(height: 16),
              _buildDialogField(newCtrl, 'New Access Key', isDark, isPassword: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abort', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBB86FC),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () {
                if (currentCtrl.text.isNotEmpty && newCtrl.text.isNotEmpty) {
                  _updateAccessKey(context, currentCtrl.text, newCtrl.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Update', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController ctrl, String hint, bool isDark, {bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.inter(color: isDark ? Colors.white24 : Colors.black45, fontSize: 12),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBB86FC))),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Terminate Session?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          content: Text('You will need to authorize again to access your data.', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black54, fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38))),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                _auth.signOut();
                Navigator.pop(context); // Exit Profile Screen
              },
              child: Text('Terminate', style: GoogleFonts.inter(color: const Color(0xFFCF6679), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}