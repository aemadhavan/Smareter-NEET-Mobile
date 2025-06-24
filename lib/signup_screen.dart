import 'package:flutter/material.dart';
// Assuming you have the Clerk Flutter SDK
import 'package:logging/logging.dart';
final _logger = Logger('SignUpScreen');

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}
class SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      // Placeholder for Clerk sign-up logic
      // You'll replace this with actual Clerk SDK calls
      // Example:
      // await Clerk.instance.signUp.create(
      //   emailAddress: email,
      //   password: password,
      // );

      // On successful sign-up, navigate to another screen (e.g., home)
      // Navigator.pushReplacementNamed(context, '/home');

      // For now, just print the input
      _logger.info('Attempting to sign up with Email: $email, Password: $password');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up attempted (placeholder)')),
      );

    } catch (e) {
      // Handle sign-up errors
      _logger.severe('Sign up error: $e');ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),

      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _signUp,
              child: Text('Sign Up'),
            ),
            SizedBox(height: 12.0),
            TextButton(
              onPressed: () {
                // Navigate to sign-in screen
                Navigator.pushReplacementNamed(context, '/sign_in');
              },
              child: Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}