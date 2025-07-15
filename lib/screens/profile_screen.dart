import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/screens/login_screen.dart';
import 'package:bingebuddy/screens/about_us_screen.dart';
import 'package:bingebuddy/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  String? _username;
  String? _email;
  Map<String, dynamic>? _userCounts;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to view your profile';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch user details
      final userResponse = await _apiService.getUserDetails(user.userId);
      if (userResponse['status'] != 'success') {
        throw Exception(userResponse['error'] ?? 'Failed to fetch user details');
      }

      // Fetch user counts
      final countsResponse = await _apiService.getUserCounts(user.userId);

      setState(() {
        _username = userResponse['username'];
        _email = userResponse['email'];
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

  Future<void> _openTermsOfUse() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252736),
        title: const Text(
          'Terms of Use',
          style: TextStyle(color: Color(0xFFEAEAEA)),
        ),
        content: const Text(
          'This link will direct you to a browser to open the Terms of Use page.',
          style: TextStyle(color: Color(0xFFEAEAEA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFF72585)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Accept',
              style: TextStyle(color: Color(0xFF12CDC9)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      const termsUrl = 'https://www.termsfeed.com/live/fda9ebaf-fde5-4357-9b9a-3ff6958b8466';
      final uri = Uri.parse(termsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Terms of Use page')),
        );
      }
    }
  }
 @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFF1F1D2B),
      body: SafeArea(
        child: SizedBox.expand(
          child: Container(
            color: const Color(0xFF1F1D2B),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      // User Details
                      Card(
                        color: const Color(0xFF252736),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            'Username: ${_username ?? 'Loading...'}',
                            style: const TextStyle(color: Color(0xFFEAEAEA)),
                          ),
                        ),
                      ),
                      Card(
                        color: const Color(0xFF252736),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            'Email: ${_email ?? 'Loading...'}',
                            style: const TextStyle(color: Color(0xFFEAEAEA)),
                          ),
                        ),
                      ),
                      Card(
                        color: const Color(0xFF252736),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: const Text(
                            'Password: ***********',
                            style: TextStyle(color: Color(0xFFEAEAEA)),
                          ),
                          subtitle: const Text(
                            'Password is masked for security',
                            style: TextStyle(color: Color(0xFF92929D)),
                          ),
                        ),
                      ),
                      // Your Data Section
                      const SizedBox(height: 20),
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
                                                  color:
                                                      const Color(0xFF12CDC9),
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
                                                        color:
                                                            Color(0xFF12CDC9),
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Watchlist',
                                                        style: TextStyle(
                                                          color: Color(
                                                              0xFFEAEAEA),
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
                                                      color:
                                                          Color(0xFFEAEAEA),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    'TV Shows: ${_userCounts!['watchlist']['tvShows']}',
                                                    style: TextStyle(
                                                      color:
                                                          Color(0xFFEAEAEA),
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
                                                  color:
                                                      const Color(0xFF4CAF50),
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
                                                        color:
                                                            Color(0xFF4CAF50),
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Watched',
                                                        style: TextStyle(
                                                          color: Color(
                                                              0xFFEAEAEA),
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
                                                      color:
                                                          Color(0xFFEAEAEA),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    'TV Shows: ${_userCounts!['watched']['tvShows']}',
                                                    style: TextStyle(
                                                      color:
                                                          Color(0xFFEAEAEA),
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
                      const SizedBox(height: 20),
                      // Action Buttons
                      ElevatedButton(
                        onPressed: _deleteUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF72585),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: const Text(
                          'Delete User',
                          style: TextStyle(
                              color: Color(0xFF1F1D2B), fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _openTermsOfUse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF12CDC9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: const Text(
                          'Terms of Use',
                          style: TextStyle(
                              color: Color(0xFF1F1D2B), fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AboutUsScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF12CDC9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: const Text(
                          'About Us',
                          style: TextStyle(
                              color: Color(0xFF1F1D2B), fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await authProvider.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF12CDC9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                              color: Color(0xFF1F1D2B), fontSize: 16),
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
      ),
    );
  }
  }