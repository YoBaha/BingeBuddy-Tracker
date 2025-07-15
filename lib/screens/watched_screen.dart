import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/models/watched_item.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/services/api_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:bingebuddy/utils/export_utils.dart';

class WatchedScreen extends StatefulWidget {
  const WatchedScreen({super.key});

  @override
  _WatchedScreenState createState() => _WatchedScreenState();
}

class _WatchedScreenState extends State<WatchedScreen> {
  final ApiService _apiService = ApiService();
  List<WatchedItem> _watchedItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'All'; // Rating filter
  String _contentType = 'All'; // Content type filter: All, Movies, TV Shows

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
      if (user == null) {
        setState(() {
          _errorMessage = 'Please log in to view your watched items';
        });
        return;
      }

      final response = await _apiService.getWatchedItems(user.userId);
      setState(() {
        _watchedItems = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching watched items: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching watched items: $e';
      });
    }
  }

  Future<void> _removeFromWatched(WatchedItem item) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || item.id == null) return;

    try {
      await _apiService.removeFromWatched(user.userId, item.itemId, item.itemType);
      setState(() {
        _watchedItems.remove(item);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${item.metadata['title'] ?? item.metadata['name'] ?? 'Unknown'} from watched list')),
      );
    } catch (e) {
      print('Error removing from watched: $e');
      setState(() {
        _errorMessage = 'Error removing item: $e';
      });
    }
  }

  Future<void> _updateRating(WatchedItem item, int newRating) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || item.id == null) return;

    try {
      await _apiService.updateWatchedItem(item.id!, newRating, item.metadata);
      setState(() {
        final index = _watchedItems.indexOf(item);
        if (index != -1) {
          _watchedItems[index] = WatchedItem(
            id: item.id,
            itemId: item.itemId,
            itemType: item.itemType,
            rating: newRating,
            metadata: item.metadata,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating updated to $newRating')),
      );
    } catch (e) {
      print('Error updating rating: $e');
      setState(() {
        _errorMessage = 'Error updating rating: $e';
      });
    }
  }

  Future<void> _exportWatched(String format) async {
    if (_watchedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Watched list is empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String path;
      String subject = 'My BingeBuddy Watched List';
      if (format == 'csv') {
        path = await ExportUtils.exportWatchedToCsv(_watchedItems, context);
      } else {
        path = await ExportUtils.exportWatchedToPdf(_watchedItems, context);
      }
      await ExportUtils.shareFile(path, subject);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Watched list exported as $format')),
      );
    } catch (e) {
      print('Error exporting watched list: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error exporting watched list: $e';
      });
      if (e.toString().contains('Storage permission denied')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied. Please enable it in settings.')),
        );
      }
    }
  }

  List<WatchedItem> _getFilteredItems(int min, int max) {
    var filteredItems = _watchedItems
        .where((item) => item.rating >= min && item.rating <= max)
        .toList();

    if (_contentType != 'All') {
      filteredItems = filteredItems
          .where((item) => item.itemType == (_contentType == 'Movies' ? 'movie' : 'tv'))
          .toList();
    }

    return filteredItems..sort((a, b) => b.rating.compareTo(a.rating));
  }

  Widget _buildRatingSection(String title, String subtitle, int minRating, int maxRating) {
    final items = _getFilteredItems(minRating, maxRating);
    if (items.isEmpty || (_selectedFilter != 'All' && !['Low', 'Medium', 'High'].contains(_selectedFilter))) {
      return const SizedBox.shrink();
    }

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
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final title = item.metadata['title'] ?? item.metadata['name'] ?? 'Unknown';
            final imageUrl = item.metadata['poster_path'] != null
                ? 'https://image.tmdb.org/t/p/w500${item.metadata['poster_path']}'
                : null;
            return Card(
              color: const Color(0xFF252736),
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
                          initialRating: item.rating.toDouble(),
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
                            _updateRating(item, rating.round());
                          },
                        ),
                        Text(
                          '$title (${item.itemType})',
                          style: const TextStyle(color: Color(0xFFEAEAEA)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFF72585)),
                    onPressed: () => _removeFromWatched(item),
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
      backgroundColor: const Color(0xFF1F1D2B),
      appBar: AppBar(
        title: const Text('Watched Items', style: TextStyle(color: Color(0xFFFFFFFF))),
        backgroundColor: const Color(0xFF1F1D2B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF4CAF50)),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF252736),
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description, color: Color(0xFF4CAF50)),
                      title: const Text('Export as CSV', style: TextStyle(color: Color(0xFFEAEAEA))),
                      onTap: () {
                        Navigator.pop(context);
                        _exportWatched('csv');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF4CAF50)),
                      title: const Text('Export as PDF', style: TextStyle(color: Color(0xFFEAEAEA))),
                      onTap: () {
                        Navigator.pop(context);
                        _exportWatched('pdf');
                      },
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Export Watched List',
          ),
          if (authProvider.user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFFFFFFF)),
              onPressed: () async {
                await authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              tooltip: 'Logout',
            ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1F1D2B),
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
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'All',
                        label: Text('All'),
                        icon: Icon(Icons.all_inclusive),
                      ),
                      ButtonSegment<String>(
                        value: 'Movies',
                        label: Text('Movies'),
                        icon: Icon(Icons.movie),
                      ),
                      ButtonSegment<String>(
                        value: 'TV Shows',
                        label: Text('TV Shows'),
                        icon: Icon(Icons.tv),
                      ),
                    ],
                    selected: {_contentType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _contentType = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF4CAF50);
                        }
                        return const Color(0xFF252736);
                      }),
                      foregroundColor: WidgetStateProperty.all(const Color(0xFFEAEAEA)),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        AppBar().preferredSize.height -
                        MediaQuery.of(context).padding.top -
                        160, // Adjust for header, content type, and rating buttons
                  ),
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
                              : Column(
                                  children: [
                                    _buildRatingSection('High Rating', 'Rated 4-5 stars', 4, 5),
                                    _buildRatingSection('Medium Rating', 'Rated 2-3 stars', 2, 3),
                                    _buildRatingSection('Low Rating', 'Rated 1 star', 1, 1),
                                    const SizedBox(height: 60),
                                  ],
                                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}