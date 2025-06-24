import 'package:flutter/material.dart';

import 'package:clerk_flutter/clerk_flutter.dart';

void main() {
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
                  return const ClerkUserButton();
                },
                signedOutBuilder: (context, authState) {
                  return const ClerkAuthentication();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
