import 'package:bingebuddy/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bingebuddy/main.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/screens/login_screen.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Mock SharedPreferences to simulate no logged-in user
    SharedPreferences.setMockInitialValues({});

    // Create a mock AuthProvider
    final authProvider = AuthProvider();
    await authProvider.loadUser(); // Ensure no user is loaded

    // Build the app and trigger a frame
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: BingeBuddyApp(authProvider: authProvider), // Pass authProvider
      ),
    );

    // Wait for the UI to settle
    await tester.pumpAndSettle();

    // Verify the login screen is displayed
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login - BingeBuddy'), findsOneWidget);
    expect(find.text('Username or Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Need an account? Sign up'), findsOneWidget);
  });

  testWidgets('Sign-up screen displays correctly', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Create a mock AuthProvider
    final authProvider = AuthProvider();
    await authProvider.loadUser();

    // Build the app and trigger a frame
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: BingeBuddyApp(authProvider: authProvider), // Pass authProvider
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to sign-up screen
    await tester.tap(find.text('Need an account? Sign up'));
    await tester.pumpAndSettle();

    // Verify the sign-up screen
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(find.text('Sign Up - BingeBuddy'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);
  });
}