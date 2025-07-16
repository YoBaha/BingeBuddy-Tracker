import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1D2B), 
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(color: Color(0xFFEAEAEA))),
        backgroundColor: const Color(0xFF1F1D2B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEAEAEA)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          color: const Color(0xFF1F1D2B),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      AppBar().preferredSize.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20), 
                      const Text(
                        'About BingeBuddy',
                        style: TextStyle(
                          color: Color(0xFFEAEAEA),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'BingeBuddy is your ultimate companion for tracking movies and TV shows. Powered by the TMDB API, we help you discover, save, and manage your watchlist with ease.',
                        style: TextStyle(color: Color(0xFFEAEAEA), fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/tmdb_logo.png',
                        height: 100,
                        width: 100,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                        style: TextStyle(color: Color(0xFF92929D), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF12CDC9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: const Text('Back', style: TextStyle(color: Color(0xFF1F1D2B), fontSize: 16)),
                      ),
                      const SizedBox(height: 20), 
                    ],
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