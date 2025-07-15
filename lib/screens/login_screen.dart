import 'package:bingebuddy/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.login(
        _usernameOrEmailController.text,
        _passwordController.text,
      );
      if (error == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavigation()),
        );
      } else {
        setState(() {
          _errorMessage = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.5; // Reduced to 50% for better fit

    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resizing for keyboard
      backgroundColor: const Color(0xFF1F1D2B), // Ensure scaffold background matches
      appBar: AppBar(
        title: const Text('BingeBuddy', style: TextStyle(color: Color(0xFFFFFFFF))),
        backgroundColor: const Color(0xFF1F1D2B),
      ),
      body: SizedBox.expand(
        child: Container(
          color: const Color(0xFF1F1D2B), // Ensure container covers all
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      AppBar().preferredSize.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Image.asset(
                          'assets/logo.png',
                          height: logoSize,
                          width: logoSize,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameOrEmailController,
                          decoration: InputDecoration(
                            labelText: 'Username or Email',
                            labelStyle: const TextStyle(color: Color(0xFFEAEAEA)),
                            filled: true,
                            fillColor: const Color(0xFF252736),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          style: const TextStyle(color: Color(0xFFEAEAEA)),
                          validator: (value) => value!.isEmpty ? 'Enter username or email' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Color(0xFFEAEAEA)),
                            filled: true,
                            fillColor: const Color(0xFF252736),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          style: const TextStyle(color: Color(0xFFEAEAEA)),
                          obscureText: true,
                          validator: (value) => value!.isEmpty ? 'Enter a password' : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF12CDC9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: const Text('Login', style: TextStyle(color: Color(0xFF1F1D2B), fontSize: 16)),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFF72585))),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          ),
                          child: const Text('Need an account? Sign up', style: TextStyle(color: Color(0xFF12CDC9))),
                        ),
                        const SizedBox(height: 20), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}