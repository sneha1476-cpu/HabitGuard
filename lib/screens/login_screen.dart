import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign in with Google.
      final User? user = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        // Save logged-in user's profile to Firestore.
        await _firestoreService.saveUserProfile(user);

        // Get the FCM device token after login.
        final String? fcmToken =
            await FirebaseMessaging.instance.getToken();

        // Save FCM token to the logged-in user's Firestore document.
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _firestoreService.saveFcmToken(fcmToken);
        }

        if (!mounted) return;

        // Open existing HabitGuard Dashboard.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 90,
                  color: Colors.indigo,
                ),

                const SizedBox(height: 24),

                const Text(
                  'HabitGuard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'AI-Powered Digital Wellbeing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 48),

                const Text(
                  'Welcome to HabitGuard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),

                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}