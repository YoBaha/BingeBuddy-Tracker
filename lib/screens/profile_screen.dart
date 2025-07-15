import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/screens/login_screen.dart';
import 'package:bingebuddy/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  String? _username;
  String? _email;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    try {
      final response = await _apiService.getUserDetails(user.userId);
      if (response['status'] == 'success') {
        setState(() {
          _username = response['username'];
          _email = response['email'];
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to fetch user details';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user details: $e';
      });
    }
  }

  Future<void> _deleteUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    try {
      final response = await _apiService.deleteUser(user.userId);
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        await authProvider.logout();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to delete user';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting user: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Material( 
      child: Container(
        color: const Color(0xFF1F1D2B),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'User Profile',
                style: TextStyle(
                  color: Color(0xFFEAEAEA),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Card(
                color: Color(0xFF252736),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text('Username: ${_username ?? 'Loading...'}', style: TextStyle(color: Color(0xFFEAEAEA))),
                ),
              ),
              Card(
                color: Color(0xFF252736),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text('Email: ${_email ?? 'Loading...'}', style: TextStyle(color: Color(0xFFEAEAEA))),
                ),
              ),
              Card(
                color: Color(0xFF252736),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: const Text('Password: ****', style: TextStyle(color: Color(0xFFEAEAEA))),
                  subtitle: const Text('Password is masked for security', style: TextStyle(color: Color(0xFF92929D))),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFF72585))),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _deleteUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF72585),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Delete User', style: TextStyle(color: Color(0xFF1F1D2B), fontSize: 16)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await authProvider.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF12CDC9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Logout', style: TextStyle(color: Color(0xFF1F1D2B), fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}