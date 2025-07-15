import 'package:flutter/material.dart';
import 'package:bingebuddy/bottom_navigation.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1F1D2B),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to BingeBuddy!',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Explore your favorite movies and TV shows or manage your watchlist.',
            style: TextStyle(color: Color(0xFF92929D), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              BottomNavigation().navigateTo(1, context); // Navigate to Home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12CDC9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Home', style: TextStyle(color: Color(0xFF1F1D2B))),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              BottomNavigation().navigateTo(2, context); // Navigate to Watchlist
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12CDC9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Watchlist', style: TextStyle(color: Color(0xFF1F1D2B))),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              BottomNavigation().navigateTo(3, context); // Navigate to wathed
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12CDC9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Watched Shows', style: TextStyle(color: Color(0xFF1F1D2B))),
          ),
           const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              BottomNavigation().navigateTo(4, context); // Navigate to Profile
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12CDC9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Profile', style: TextStyle(color: Color(0xFF1F1D2B))),
          ),
        ],
      ),
    );
  }
}