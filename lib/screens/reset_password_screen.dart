import 'package:flutter/material.dart';
import 'package:bingebuddy/services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _apiService = ApiService();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.resetPassword(
        widget.email,
        _codeController.text,
        _newPasswordController.text,
      );
      if (response['status'] == 'success') {
        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to reset password';
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
        title: const Text('Reset Password', style: TextStyle(color: Color(0xFFFFFFFF))),
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
              'Enter the 4-digit code sent to your email and your new password',
              style: TextStyle(color: Color(0xFFEAEAEA), fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Reset Code',
                labelStyle: TextStyle(color: Color(0xFF92929D)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF12CDC9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF12CDC9)),
                ),
              ),
              style: const TextStyle(color: Color(0xFFEAEAEA)),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Color(0xFF92929D)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF12CDC9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF12CDC9)),
                ),
              ),
              style: const TextStyle(color: Color(0xFFEAEAEA)),
              obscureText: true,
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
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12CDC9),
                      foregroundColor: const Color(0xFFEAEAEA),
                    ),
                    child: const Text('Reset Password'),
                  ),
          ],
        ),
      ),
    );
  }
}