import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bingebuddy/models/watchlist_item.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _selectedTab = 'movies';
  List<dynamic> _items = [];
  List<dynamic> _movieRecommendations = [];
  List<dynamic> _tvRecommendations = [];
  bool _isLoading = false;
  bool _isRecommendationsLoading = false;
  String? _errorMessage;
  String? _recommendationsError;
  final _searchController = TextEditingController();
  DateTime? _lastRequestTime;
  dynamic _selectedItem;

  @override
  void initState() {
    super.initState();
    _fetchContent();
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContent() async {
    if (_lastRequestTime != null &&
        DateTime.now().difference(_lastRequestTime!).inMilliseconds < 200) {
      await Future.delayed(Duration(
          milliseconds: 200 -
              DateTime.now().difference(_lastRequestTime!).inMilliseconds));
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _items = [];
    });

    try {
      Map<String, dynamic> response;
      final query = _searchController.text.isEmpty ? null : _searchController.text;
      print('Fetching content for tab: $_selectedTab, query: $query');

      if (_selectedTab == 'movies') {
        response = query == null
            ? await _apiService.getTrendingMovies()
            : await _apiService.searchMovies(query);
        _items = response['results'] ?? [];
      } else {
        response = query == null
            ? await _apiService.getTrendingTv()
            : await _apiService.searchTv(query);
        _items = response['results'] ?? [];
      }

      print('Response for $_selectedTab: $response');
      print('Items count for $_selectedTab: ${_items.length}');

      if (_items.isEmpty) {
        setState(() {
          _errorMessage = 'No ${_selectedTab} found';
        });
      }
      setState(() {
        _isLoading = false;
        _lastRequestTime = DateTime.now();
      });
    } catch (e, stackTrace) {
      print('Error fetching $_selectedTab: $e\n$stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching $_selectedTab: $e';
      });
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isRecommendationsLoading = true;
      _recommendationsError = null;
      _movieRecommendations = [];
      _tvRecommendations = [];
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      int? movieId;
      int? tvId;

      // Get user watchlist
      final watchlist = authProvider.user != null
          ? await _apiService.getWatchlist(authProvider.user!.userId)
          : [];

      // Select movie ID: highest priority from watchlist, then trending
      final movieWatchlist = watchlist.where((item) => item.itemType == 'movie').toList();
      if (movieWatchlist.isNotEmpty) {
        movieId = int.parse(movieWatchlist.first.itemId);
      } else {
        final trendingMovies = (await _apiService.getTrendingMovies())['results'] ?? [];
        movieId = trendingMovies.isNotEmpty ? trendingMovies[0]['id'] : 541671; // Fallback: "Ballerina"
      }

      // Select TV ID: highest priority from watchlist, then trending
      final tvWatchlist = watchlist.where((item) => item.itemType == 'tv').toList();
      if (tvWatchlist.isNotEmpty) {
        tvId = int.parse(tvWatchlist.first.itemId);
      } else {
        final trendingTv = (await _apiService.getTrendingTv())['results'] ?? [];
        tvId = trendingTv.isNotEmpty ? trendingTv[0]['id'] : 1396; 
      }

      // Fetch recommendations
      final movieResponse = await _apiService.getMovieRecommendations(movieId!);
      final tvResponse = await _apiService.getTvRecommendations(tvId!);

      setState(() {
        _movieRecommendations = (movieResponse['results'] ?? []).take(5).toList();
        _tvRecommendations = (tvResponse['results'] ?? []).take(5).toList();
        _isRecommendationsLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching recommendations: $e\n$stackTrace');
      setState(() {
        _isRecommendationsLoading = false;
        _recommendationsError = 'Error fetching recommendations: $e';
      });
    }
  }

  Future<void> _fetchItemDetails(String mediaType, int id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final details = await _apiService.getItemDetails(mediaType, id);
      setState(() {
        _selectedItem = details;
        _isLoading = false;
      });
      _showDetailsModal();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching details: $e';
        _isLoading = false;
      });
    }
  }

  void _showDetailsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252736),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _selectedItem != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedItem['title'] ?? _selectedItem['name'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Color(0xFFEAEAEA),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedItem['overview'] ?? 'No overview available',
                            style: const TextStyle(color: Color(0xFFEAEAEA)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rating: ${_selectedItem['vote_average']?.toStringAsFixed(1) ?? '0'}/10',
                            style: const TextStyle(color: Color(0xFF92929D)),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedItem['credits'] != null &&
                              _selectedItem['credits']['cast'] != null)
                            Text(
                              'Cast: ${_selectedItem['credits']['cast'].take(3).map((cast) => cast['name']).join(', ')}',
                              style: const TextStyle(color: Color(0xFFEAEAEA)),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => _addToWatchlist(_selectedItem),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF12CDC9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Add to Watchlist'),
                              ),
                              ElevatedButton(
                                onPressed: () => _addToWatched(_selectedItem),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF38EF7D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Mark as Watched'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF72585),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                        ],
                      )
                    : const Center(child: Text('Loading...', style: TextStyle(color: Color(0xFFEAEAEA)))),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addToWatchlist(dynamic item) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to watchlist')),
      );
      return;
    }

    String itemId = item['id']?.toString() ?? 'unknown';
    String itemType = item['media_type'] ?? (item['title'] != null ? 'movie' : 'tv');
    Map<String, dynamic> metadata = {
      'title': item['title'] ?? item['name'] ?? 'Unknown',
      'poster_path': item['poster_path'] ?? '',
    };

    int? selectedPriority = await _showPriorityDialog();
    if (selectedPriority == null) return;

    print('Adding to watchlist: userId=${user.userId}, itemId=$itemId, itemType=$itemType, priority=$selectedPriority, metadata=$metadata');

    try {
      final response = await _apiService.addToWatchlist(
        userId: user.userId,
        itemId: itemId,
        itemType: itemType,
        priority: selectedPriority,
        metadata: metadata,
      );
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${metadata['title']} to your watchlist!')),
        );
        await _fetchRecommendations();
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to add to watchlist';
        });
      }
    } catch (e) {
      print('Error adding to watchlist: $e');
      setState(() {
        _errorMessage = 'Error adding to watchlist: $e';
      });
    }
  }

  Future<void> _addToWatched(dynamic item) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to mark as watched')),
      );
      return;
    }

    String itemId = item['id']?.toString() ?? 'unknown';
    String itemType = item['media_type'] ?? (item['title'] != null ? 'movie' : 'tv');
    Map<String, dynamic> metadata = {
      'title': item['title'] ?? item['name'] ?? 'Unknown',
      'poster_path': item['poster_path'] ?? '',
    };

    int? selectedRating = await _showRatingDialog();
    if (selectedRating == null) return;

    print('Adding to watched: userId=${user.userId}, itemId=$itemId, itemType=$itemType, rating=$selectedRating, metadata=$metadata');

    try {
      final response = await _apiService.addToWatched(
        userId: user.userId,
        itemId: itemId,
        itemType: itemType,
        rating: selectedRating,
        metadata: metadata,
      );
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${metadata['title']} to your watched list!')),
        );
        await _fetchRecommendations();
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to add to watched';
        });
      }
    } catch (e) {
      print('Error adding to watched: $e');
      setState(() {
        _errorMessage = 'Error adding to watched: $e';
      });
    }
  }

  Future<int?> _showPriorityDialog() async {
    int selectedPriority = 1;
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Priority', style: TextStyle(color: Color(0xFFEAEAEA))),
          backgroundColor: const Color(0xFF252736),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: selectedPriority,
                    dropdownColor: const Color(0xFF252736),
                    style: const TextStyle(color: Color(0xFFEAEAEA)),
                    underline: Container(height: 2, color: const Color(0xFF12CDC9)),
                    items: List.generate(5, (index) => index + 1)
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('Priority $value', style: const TextStyle(color: Color(0xFFEAEAEA))),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedPriority = newValue;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF12CDC9))),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add', style: TextStyle(color: Color(0xFF12CDC9))),
              onPressed: () => Navigator.of(context).pop(selectedPriority),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _showRatingDialog() async {
    int selectedRating = 1;
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Rating', style: TextStyle(color: Color(0xFFEAEAEA))),
          backgroundColor: const Color(0xFF252736),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: selectedRating,
                    dropdownColor: const Color(0xFF252736),
                    style: const TextStyle(color: Color(0xFFEAEAEA)),
                    underline: Container(height: 2, color: const Color(0xFF12CDC9)),
                    items: List.generate(5, (index) => index + 1)
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('Rating $value', style: const TextStyle(color: Color(0xFFEAEAEA))),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedRating = newValue;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF12CDC9))),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add', style: TextStyle(color: Color(0xFF12CDC9))),
              onPressed: () => Navigator.of(context).pop(selectedRating),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: const Color(0xFF1F1D2B),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ToggleButtons(
                  isSelected: [
                    _selectedTab == 'movies',
                    _selectedTab == 'tv',
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedTab = index == 0 ? 'movies' : 'tv';
                      _searchController.clear();
                      _items = [];
                    });
                    _fetchContent();
                  },
                  color: const Color(0xFFEAEAEA),
                  selectedColor: const Color(0xFF1F1D2B),
                  fillColor: const Color(0xFF12CDC9),
                  borderRadius: BorderRadius.circular(12),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Movies', style: TextStyle(color: Color(0xFFEAEAEA))),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('TV Shows', style: TextStyle(color: Color(0xFFEAEAEA))),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search $_selectedTab',
                    labelStyle: const TextStyle(color: Color(0xFFEAEAEA)),
                    filled: true,
                    fillColor: const Color(0xFF252736),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFFEAEAEA)),
                      onPressed: _fetchContent,
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFFEAEAEA)),
                  onSubmitted: (_) => _fetchContent(),
                ),
              ),
              // Recommended for You Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF252736),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Recommended for You',
                          style: TextStyle(
                            color: Color(0xFFEAEAEA),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isRecommendationsLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF12CDC9)))
                          : _recommendationsError != null
                              ? Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        _recommendationsError!,
                                        style: const TextStyle(color: Color(0xFFEAEAEA)),
                                      ),
                                      TextButton(
                                        onPressed: _fetchRecommendations,
                                        child: const Text('Retry', style: TextStyle(color: Color(0xFF12CDC9))),
                                      ),
                                    ],
                                  ),
                                )
                              : _movieRecommendations.isEmpty && _tvRecommendations.isEmpty
                                  ? const Center(
                                      child: Text('No recommendations available',
                                          style: TextStyle(color: Color(0xFFEAEAEA))))
                                  : SizedBox(
                                      height: 200,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _movieRecommendations.length + _tvRecommendations.length,
                                        itemBuilder: (context, index) {
                                          final isMovie = index < _movieRecommendations.length;
                                          final item = isMovie
                                              ? _movieRecommendations[index]
                                              : _tvRecommendations[index - _movieRecommendations.length];
                                          final title = item['title'] ?? item['name'] ?? 'Unknown';
                                          final imageUrl = item['poster_path'] != null
                                              ? 'https://image.tmdb.org/t/p/w200${item['poster_path']}'
                                              : null;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                            child: GestureDetector(
                                              onTap: () => _fetchItemDetails(
                                                  isMovie ? 'movie' : 'tv', item['id']),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    child: imageUrl != null
                                                        ? CachedNetworkImage(
                                                            imageUrl: imageUrl,
                                                            width: 120,
                                                            fit: BoxFit.cover,
                                                            placeholder: (context, url) =>
                                                                const CircularProgressIndicator(),
                                                            errorWidget: (context, url, error) => const Icon(
                                                                Icons.image_not_supported,
                                                                color: Color(0xFFEAEAEA)),
                                                          )
                                                        : const Icon(Icons.image_not_supported,
                                                            color: Color(0xFFEAEAEA)),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  SizedBox(
                                                    width: 120,
                                                    child: Text(
                                                      title,
                                                      style: const TextStyle(color: Color(0xFFEAEAEA)),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                    ],
                  ),
                ),
              ),
              // Trending Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trending ${_selectedTab == 'movies' ? 'Movies' : 'TV Shows'}',
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF12CDC9)))
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEAEAEA))),
                                    TextButton(
                                      onPressed: _fetchContent,
                                      child: const Text('Retry',
                                          style: TextStyle(color: Color(0xFF12CDC9))),
                                    ),
                                  ],
                                ),
                              )
                            : _items.isEmpty
                                ? const Center(
                                    child: Text('No items to display',
                                        style: TextStyle(color: Color(0xFFEAEAEA))))
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.7,
                                      crossAxisSpacing: 8.0,
                                      mainAxisSpacing: 8.0,
                                    ),
                                    itemCount: _items.length,
                                    itemBuilder: (context, index) {
                                      final item = _items[index];
                                      final title = item['title'] ?? item['name'] ?? 'Unknown';
                                      final imageUrl = item['poster_path'] != null
                                          ? 'https://image.tmdb.org/t/p/w500${item['poster_path']}'
                                          : null;
                                      return GestureDetector(
                                        onTap: () => _fetchItemDetails(
                                            _selectedTab == 'movies' ? 'movie' : 'tv', item['id']),
                                        child: Card(
                                          color: const Color(0xFF252736),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: imageUrl != null
                                                    ? CachedNetworkImage(
                                                        imageUrl: imageUrl,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) =>
                                                            const CircularProgressIndicator(),
                                                        errorWidget: (context, url, error) => const Icon(
                                                            Icons.image_not_supported,
                                                            color: Color(0xFFEAEAEA)),
                                                      )
                                                    : const Icon(Icons.image_not_supported,
                                                        color: Color(0xFFEAEAEA)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  title,
                                                  style: const TextStyle(color: Color(0xFFEAEAEA)),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.add, color: Color(0xFF12CDC9)),
                                                    onPressed: () => _addToWatchlist(item),
                                                    tooltip: 'Add to Watchlist',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.check, color: Color(0xFF38EF7D)),
                                                    onPressed: () => _addToWatched(item),
                                                    tooltip: 'Mark as Watched',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}