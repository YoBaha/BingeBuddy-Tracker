import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/services/api_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class WatchedScreen extends StatefulWidget {
  const WatchedScreen({super.key});

  @override
  _WatchedScreenState createState() => _WatchedScreenState();
}

class _WatchedScreenState extends State<WatchedScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _watchedItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchWatchedItems();
  }

  Future<void> _fetchWatchedItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      final response = await _apiService.getWatchedItems(user.userId);
      setState(() {
        _watchedItems = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching watched items: $e';
      });
    }
  }

  Future<void> _removeFromWatched(int id, String itemId, String itemType) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      await _apiService.removeFromWatched(user.userId, itemId, itemType);
      setState(() {
        _watchedItems.removeWhere((item) => item['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from watched list')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error removing item: $e';
      });
    }
  }

  Future<void> _updateRating(int id, int newRating) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      final item = _watchedItems.firstWhere((item) => item['id'] == id);
      await _apiService.updateWatchedItem(id, newRating, item['metadata']);
      setState(() {
        item['rating'] = newRating;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating updated to $newRating')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating rating: $e';
      });
    }
  }

  List<dynamic> _getItemsByRatingRange(int min, int max) {
    return _watchedItems
        .where((item) => item['rating'] >= min && item['rating'] <= max)
        .toList()
      ..sort((a, b) => b['rating'].compareTo(a['rating']));
  }

  Widget _buildRatingSection(String title, String subtitle, int minRating, int maxRating) {
    final items = _getItemsByRatingRange(minRating, maxRating);
    if (items.isEmpty || _selectedFilter != 'All' && !['Low', 'Medium', 'High'].contains(_selectedFilter)) return const SizedBox.shrink();

    // Show only if filter matches or no filter is applied
    if (_selectedFilter == 'Low' && minRating != 1) return const SizedBox.shrink();
    if (_selectedFilter == 'Medium' && minRating != 2) return const SizedBox.shrink();
    if (_selectedFilter == 'High' && minRating != 4) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFEAEAEA),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF92929D), fontSize: 14),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final title = item['metadata']['title'] ?? item['metadata']['name'] ?? 'Unknown';
            final imageUrl = item['metadata']['poster_path'] != null
                ? 'https://image.tmdb.org/t/p/w500${item['metadata']['poster_path']}'
                : null;
            return Card(
              color: Color(0xFF252736),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF4CAF50), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Color(0xFFEAEAEA)),
                          )
                        : const Icon(Icons.image_not_supported, color: Color(0xFFEAEAEA)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBar.builder(
                          initialRating: item['rating'].toDouble(),
                          minRating: 1,
                          maxRating: 5,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 20,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Color(0xFF4CAF50),
                          ),
                          onRatingUpdate: (rating) {
                            _updateRating(item['id'], rating.round());
                          },
                        ),
                        Text(
                          '$title (${item['item_type']})',
                          style: const TextStyle(color: Color(0xFFEAEAEA)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFF72585)),
                    onPressed: () => _removeFromWatched(item['id'], item['item_id'], item['item_type']),
                    tooltip: 'Remove from Watched',
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watched Items', style: TextStyle(color: Color(0xFFFFFFFF))),
        backgroundColor: const Color(0xFF1F1D2B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (authProvider.user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFFFFFFF)),
              onPressed: () async {
                await authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1F1D2B),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Your Watched Movies & Shows',
                        style: TextStyle(
                          color: Color(0xFFEAEAEA),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Track and rate what you’ve already watched',
                    style: TextStyle(color: Color(0xFF92929D), fontSize: 16),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _selectedFilter = 'Low'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFilter == 'Low' ? Color(0xFF4CAF50) : Color(0xFF252736),
                      foregroundColor: Color(0xFFEAEAEA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Low (1)'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _selectedFilter = 'Medium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFilter == 'Medium' ? Color(0xFF4CAF50) : Color(0xFF252736),
                      foregroundColor: Color(0xFFEAEAEA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Medium (2-3)'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _selectedFilter = 'High'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFilter == 'High' ? Color(0xFF4CAF50) : Color(0xFF252736),
                      foregroundColor: Color(0xFFEAEAEA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('High (4-5)'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEAEAEA))),
                              TextButton(
                                onPressed: _fetchWatchedItems,
                                child: const Text('Retry', style: TextStyle(color: Color(0xFF4CAF50))),
                              ),
                            ],
                          ),
                        )
                      : _watchedItems.isEmpty
                          ? const Center(child: Text('No watched items', style: TextStyle(color: Color(0xFFEAEAEA))))
                          : ListView(
                              padding: const EdgeInsets.all(8.0),
                              children: [
                                _buildRatingSection('High Rating', 'Rated 4-5 stars', 4, 5),
                                _buildRatingSection('Medium Rating', 'Rated 2-3 stars', 2, 3),
                                _buildRatingSection('Low Rating', 'Rated 1 star', 1, 1),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}