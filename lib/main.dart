import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/screens/login_screen.dart';
import 'package:bingebuddy/screens/home_screen.dart';
import 'package:bingebuddy/screens/watchlist_screen.dart';
import 'package:bingebuddy/screens/landing_screen.dart';
import 'package:bingebuddy/screens/profile_screen.dart';
import 'package:bingebuddy/bottom_navigation.dart';

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
          '/': (context) => Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return auth.user != null ? BottomNavigation(key: GlobalKey()) : const LoginScreen();
                },
              ),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/watchlist': (context) => const WatchlistScreen(),
          '/landing': (context) => const LandingScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}