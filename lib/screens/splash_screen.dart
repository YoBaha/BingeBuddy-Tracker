import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Set system UI overlay mode for splash screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Building SplashScreen');
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    print('Starting app initialization');
    
    // Ping health check to wake up Render backend
    try {
      final success = await _apiService.pingHealthCheck();
      print(success ? 'Health check ping successful' : 'Health check ping failed');
    } catch (e) {
      print('Error during health check: $e');
    }

    // Check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await Future.delayed(const Duration(seconds: 4)); // Keep existing delay

    if (!mounted) return;

    // Reset system UI overlay mode before navigating
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);

    if (authProvider.user != null) {
      print('User authenticated, navigating to /home');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print('No user authenticated, navigating to /login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building SplashScreen UI');
    return Scaffold(
      backgroundColor: const Color(0xFF1F1D2B),
      body: Container(
        color: const Color(0xFF1F1D2B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading logo: $error');
                  return const Icon(Icons.error, size: 150, color: Colors.red);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'BingeBuddy',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}