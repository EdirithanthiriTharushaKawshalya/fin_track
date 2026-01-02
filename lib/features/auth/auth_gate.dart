import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the stream is waiting, show a loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If we have a user, show the Dashboard
        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        // Otherwise, show Login
        return const LoginScreen();
      },
    );
  }
}
