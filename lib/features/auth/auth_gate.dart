import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home_shell.dart'; 
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase automatically persists user sessions locally. 
      // This stream emits the current user if a valid local session exists.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While Firebase is initializing and checking for a persisted session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            // Matching your futuristic dark theme background
            backgroundColor: Color(0xFF0A0A0A), 
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFBB86FC), // Using your primary purple accent
              ),
            ),
          );
        }

        // 2. If a valid user snapshot with data is found, bypass login
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeShell(); 
        }

        // 3. If no session exists or user has explicitly logged out, show Login
        return const LoginScreen();
      },
    );
  }
}