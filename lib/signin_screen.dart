import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ClerkAuthBuilder(
          signedInBuilder: (context, authState) {
            // Get navigator reference before async gap
            final navigator = Navigator.of(context);
            // Use Future.microtask for immediate navigation
            Future.microtask(() {
              if (mounted) {
                navigator.pop();
              }
            });
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Signed in successfully! Redirecting...'),
                ],
              ),
            );
          },
          signedOutBuilder: (context, authState) {
            return const ClerkAuthentication();
          },
        ),
      ),
    );
  }
}