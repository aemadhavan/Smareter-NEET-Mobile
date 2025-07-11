import 'package:flutter/material.dart';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:myapp/signin_screen.dart'; // Import your sign-in screen
import 'package:myapp/signup_screen.dart'; // Import your sign-up screen
import 'package:myapp/practice_page.dart'; // Import practice page

void main() {
  // Ensure Flutter binding is initialized before runApp
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const SmaretneetApp(
      publishableKey:
          'pk_test_Y29udGVudC1yb29zdGVyLTU3LmNsZXJrLmFjY291bnRzLmRldiQ',
    ),
  );
}

/// Example App
class SmaretneetApp extends StatelessWidget {
  /// Constructs an instance of Example App
  const SmaretneetApp({super.key, required this.publishableKey});

  /// Publishable Key
  final String publishableKey;

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: publishableKey),
      child: MaterialApp(
        theme: ThemeData.light(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: ClerkErrorListener(
              child: ClerkAuthBuilder(
                signedInBuilder: (context, authState) {
                  return const PracticePage();
                },
                signedOutBuilder: (context, authState) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInScreen(),
                            ),
                          );
                        },
                        child: const Text('Sign In'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
