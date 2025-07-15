import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/bottom_navigation.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/services/api_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userCounts;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserCounts();
  }

  Future<void> _fetchUserCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to view your data';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final countsResponse = await _apiService.getUserCounts(user.userId);
      setState(() {
        _userCounts = countsResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1D2B),
      body: SafeArea(
        child: SizedBox.expand(
          child: Container(
            color: const Color(0xFF1F1D2B),
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
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
                      style: TextStyle(
                        color: Color(0xFF92929D),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Your Data Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFC4A1A), Color(0xFFF7B733)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.analytics,
                                color: Color(0xFFEAEAEA),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Your Data',
                                style: TextStyle(
                                  color: Color(0xFFEAEAEA),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFEAEAEA),
                                  ),
                                )
                              : _userCounts == null
                                  ? const Text(
                                      'No data available',
                                      style: TextStyle(
                                        color: Color(0xFFEAEAEA),
                                        fontSize: 16,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Watchlist Card
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF252736)
                                                  .withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF12CDC9),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.bookmark,
                                                      color: Color(0xFF12CDC9),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Watchlist',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFFEAEAEA),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Movies: ${_userCounts!['watchlist']['movies']}',
                                                  style: TextStyle(
                                                    color: Color(0xFFEAEAEA),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'TV Shows: ${_userCounts!['watchlist']['tvShows']}',
                                                  style: TextStyle(
                                                    color: Color(0xFFEAEAEA),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Watched Card
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF252736)
                                                  .withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF4CAF50),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle,
                                                      color: Color(0xFF4CAF50),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Watched',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFFEAEAEA),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Movies: ${_userCounts!['watched']['movies']}',
                                                  style: TextStyle(
                                                    color: Color(0xFFEAEAEA),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'TV Shows: ${_userCounts!['watched']['tvShows']}',
                                                  style: TextStyle(
                                                    color: Color(0xFFEAEAEA),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFF72585)),
                        ),
                      ),
                    const SizedBox(height: 40),
                    // Navigation Buttons
                    ElevatedButton(
                      onPressed: () {
                        BottomNavigation().navigateTo(1, context); // Navigate to Home
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12CDC9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Go to Home',
                        style: TextStyle(color: Color(0xFF1F1D2B)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        BottomNavigation().navigateTo(2, context); // Navigate to Watchlist
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12CDC9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Go to Watchlist',
                        style: TextStyle(color: Color(0xFF1F1D2B)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        BottomNavigation().navigateTo(3, context); // Navigate to Watched
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12CDC9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Go to Watched Shows/Movies',
                        style: TextStyle(color: Color(0xFF1F1D2B)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        BottomNavigation().navigateTo(4, context); // Navigate to Profile
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12CDC9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Go to Profile',
                        style: TextStyle(color: Color(0xFF1F1D2B)),
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}