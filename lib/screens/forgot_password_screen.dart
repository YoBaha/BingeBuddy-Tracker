import 'package:flutter/material.dart';
import 'package:bingebuddy/services/api_service.dart';
import 'package:bingebuddy/screens/reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _sendResetCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.forgotPassword(_emailController.text);
      if (response['status'] == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: _emailController.text),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset code sent to your email')),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to send reset code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password', style: TextStyle(color: Color(0xFFFFFFFF))),
        backgroundColor: const Color(0xFF1F1D2B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: const Color(0xFF1F1D2B),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your email to receive a reset code',
              style: TextStyle(color: Color(0xFFEAEAEA), fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Color(0xFF92929D)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF12CDC9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF12CDC9)),
                ),
              ),
              style: const TextStyle(color: Color(0xFFEAEAEA)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF12CDC9))
                : ElevatedButton(
                    onPressed: _sendResetCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12CDC9),
                      foregroundColor: const Color(0xFFEAEAEA),
                    ),
                    child: const Text('Send Reset Code'),
                  ),
          ],
        ),
      ),
    );
  }
}