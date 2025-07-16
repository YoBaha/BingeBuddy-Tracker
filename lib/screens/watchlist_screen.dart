import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/models/watchlist_item.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/services/api_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:bingebuddy/utils/export_utils.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final ApiService _apiService = ApiService();
  List<WatchlistItem> _watchlist = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'All';
  String _contentType = 'All';
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    _fetchWatchlist();
  }

  Future<void> _fetchWatchlist() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to view your watchlist';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final watchlist = await _apiService.getWatchlist(user.userId);
      setState(() {
        _watchlist = watchlist;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching watchlist: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching watchlist: $e';
      });
    }
  }

  Future<void> _removeFromWatchlist(WatchlistItem item) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || item.id == null) return;

    try {
      final response = await _apiService.removeFromWatchlist(user.userId, item.itemId, item.itemType);
      if (response['status'] == 'success') {
        setState(() {
          _watchlist.remove(item);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${item.metadata['title']} from watchlist!')),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to remove item';
        });
      }
    } catch (e) {
      print('Error removing from watchlist: $e');
      setState(() {
        _errorMessage = 'Error removing from watchlist: $e';
      });
    }
  }

  Future<void> _updatePriority(WatchlistItem item, double priority) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || item.id == null) return;

    final updatedItem = WatchlistItem(
      id: item.id,
      itemId: item.itemId,
      itemType: item.itemType,
      priority: priority.round().clamp(1, 5),
      metadata: item.metadata,
    );

    try {
      final response = await _apiService.updateWatchlistItem(item.id!, updatedItem);
      if (response['status'] == 'success') {
        setState(() {
          final index = _watchlist.indexWhere((i) => i.id == item.id);
          if (index != -1) _watchlist[index] = updatedItem;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Priority updated!')),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to update priority';
        });
      }
    } catch (e) {
      print('Error updating priority: $e');
      setState(() {
        _errorMessage = 'Error updating priority: $e';
      });
    }
  }

  Future<void> _exportWatchlist(String format) async {
    if (_watchlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Watchlist is empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String path;
      String subject = 'My BingeBuddy Watchlist';
      if (format == 'csv') {
        path = await ExportUtils.exportWatchlistToCsv(_watchlist, context);
      } else {
        path = await ExportUtils.exportWatchlistToPdf(_watchlist, context);
      }
      await ExportUtils.shareFile(path, subject);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Watchlist exported as $format')),
      );
    } catch (e) {
      print('Error exporting watchlist: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error exporting watchlist: $e';
      });
      if (e.toString().contains('Storage permission denied')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied. Please enable it in settings.')),
        );
      }
    }
  }

  List<WatchlistItem> _getFilteredItems(int min, int max) {
    var filteredItems = _watchlist
        .where((item) => item.priority >= min && item.priority <= max)
        .toList();

    if (_contentType != 'All') {
      filteredItems = filteredItems
          .where((item) => item.itemType == (_contentType == 'Movies' ? 'movie' : 'tv'))
          .toList();
    }

    return filteredItems..sort((a, b) => b.priority.compareTo(a.priority));
  }

  Widget _buildPrioritySection(String title, String subtitle, int minPriority, int maxPriority) {
    final items = _getFilteredItems(minPriority, maxPriority);
    if (items.isEmpty || (_selectedFilter != 'All' && !['Low', 'Medium', 'High'].contains(_selectedFilter))) {
      return const SizedBox.shrink();
    }

    if (_selectedFilter == 'Low' && minPriority != 1) return const SizedBox.shrink();
    if (_selectedFilter == 'Medium' && minPriority != 2) return const SizedBox.shrink();
    if (_selectedFilter == 'High' && minPriority != 4) return const SizedBox.shrink();

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
                  const Icon(Icons.bookmark_border, color: Color(0xFF12CDC9), size: 20),
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
        _isListView
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final title = item.metadata['title'] ?? item.metadata['name'] ?? 'Unknown';
                  final imageUrl = item.metadata['poster_path'] != null
                      ? 'https://image.tmdb.org/t/p/w500${item.metadata['poster_path']}'
                      : null;
                  return ListTile(
                    leading: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Color(0xFFEAEAEA)),
                          )
                        : const Icon(Icons.image_not_supported, color: Color(0xFFEAEAEA), size: 50),
                    title: Text(
                      title,
                      style: const TextStyle(color: Color(0xFFEAEAEA)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RatingBar.builder(
                          initialRating: item.priority.toDouble(),
                          minRating: 1,
                          maxRating: 5,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 20,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Color(0xFF12CDC9),
                          ),
                          onRatingUpdate: (rating) {
                            _updatePriority(item, rating);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF12CDC9)),
                          onPressed: () => _removeFromWatchlist(item),
                          tooltip: 'Remove from Watchlist',
                        ),
                      ],
                    ),
                  );
                },
              )
            : GridView.builder(
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              Text(
                                '$title (${item.itemType})',
                                style: const TextStyle(color: Color(0xFFEAEAEA)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Priority: ',
                                    style: TextStyle(color: Color(0xFF92929D), fontSize: 12),
                                  ),
                                  RatingBar.builder(
                                    initialRating: item.priority.toDouble(),
                                    minRating: 1,
                                    maxRating: 5,
                                    direction: Axis.horizontal,
                                    allowHalfRating: false,
                                    itemCount: 5,
                                    itemSize: 20,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Color(0xFF12CDC9),
                                    ),
                                    onRatingUpdate: (rating) {
                                      _updatePriority(item, rating);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF12CDC9)),
                          onPressed: () => _removeFromWatchlist(item),
                          tooltip: 'Remove from Watchlist',
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
        title: const Text('My Binge List', style: TextStyle(color: Color(0xFFFFFFFF))),
        backgroundColor: const Color(0xFF1F1D2B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isListView ? Icons.grid_view : Icons.list, color: Color(0xFFFFA726)),
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
            tooltip: _isListView ? 'Switch to Grid View' : 'Switch to List View',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFFFFFFF)),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF252736),
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description, color: Color(0xFF12CDC9)),
                      title: const Text('Export as CSV', style: TextStyle(color: Color(0xFFEAEAEA))),
                      onTap: () {
                        Navigator.pop(context);
                        _exportWatchlist('csv');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF12CDC9)),
                      title: const Text('Export as PDF', style: TextStyle(color: Color(0xFFEAEAEA))),
                      onTap: () {
                        Navigator.pop(context);
                        _exportWatchlist('pdf');
                      },
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Export Watchlist',
          ),
          if (authProvider.user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF12CDC9)),
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
                      Icon(Icons.bookmark_border, color: Color(0xFF12CDC9), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Your Binge List: To Watch',
                        style: TextStyle(
                          color: Color(0xFFEAEAEA),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Plan and prioritize your next binge',
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
                          return const Color(0xFF12CDC9);
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
                          backgroundColor: _selectedFilter == 'Low' ? Color(0xFF12CDC9) : Color(0xFF252736),
                          foregroundColor: Color(0xFFEAEAEA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Low (1)'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => _selectedFilter = 'Medium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedFilter == 'Medium' ? Color(0xFF12CDC9) : Color(0xFF252736),
                          foregroundColor: Color(0xFFEAEAEA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Medium (2-3)'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => _selectedFilter = 'High'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedFilter == 'High' ? Color(0xFF12CDC9) : Color(0xFF252736),
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
                        160, // Adjust for header, content type, and priority buttons
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF12CDC9)))
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEAEAEA))),
                                  TextButton(
                                    onPressed: _fetchWatchlist,
                                    child: const Text('Retry', style: TextStyle(color: Color(0xFF12CDC9))),
                                  ),
                                ],
                              ),
                            )
                          : _watchlist.isEmpty
                              ? const Center(child: Text('Your watchlist is empty', style: TextStyle(color: Color(0xFFEAEAEA))))
                              : Column(
                                  children: [
                                    _buildPrioritySection('High Priority', 'Watch Soon', 4, 5),
                                    _buildPrioritySection('Medium Priority', 'Watch Next', 2, 3),
                                    _buildPrioritySection('Low Priority', 'Watch Later', 1, 1),
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