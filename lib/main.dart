// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/screens/login_screen.dart';
import 'package:bingebuddy/screens/forgot_password_screen.dart';
import 'package:bingebuddy/screens/home_screen.dart';
import 'package:bingebuddy/screens/watchlist_screen.dart';
import 'package:bingebuddy/screens/landing_screen.dart';
import 'package:bingebuddy/screens/profile_screen.dart';
import 'package:bingebuddy/screens/signup_screen.dart';
import 'package:bingebuddy/screens/splash_screen.dart';
import 'package:bingebuddy/screens/logs_screen.dart';
import 'package:bingebuddy/bottom_navigation.dart';
import 'package:bingebuddy/services/api_service.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.loadUser();
  runApp(BingeBuddyApp(authProvider: authProvider));
}

class BingeBuddyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const BingeBuddyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authProvider,
      child: MaterialApp(
        title: 'BingeBuddy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.purple[50],
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const BottomNavigation(),
          '/watchlist': (context) => const WatchlistScreen(),
          '/landing': (context) => const LandingScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/signup': (context) => const SignupScreen(),
          '/logs': (context) => const LogsScreen(),
        },
      ),
    );
  }
}