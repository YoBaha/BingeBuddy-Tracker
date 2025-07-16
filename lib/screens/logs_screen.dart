// screens/logs_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bingebuddy/providers/auth_provider.dart';
import 'package:bingebuddy/services/api_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _seasonController = TextEditingController();
  final _episodeController = TextEditingController();
  final _timestampController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to view logs';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await _apiService.getLogs(user.userId);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching logs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitLog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to add a log';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _apiService.addLog(
          user.userId,
          _nameController.text,
          _seasonController.text.isEmpty ? null : int.parse(_seasonController.text),
          int.parse(_episodeController.text),
          _timestampController.text.isEmpty ? null : _timestampController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log added successfully')),
        );
        _nameController.clear();
        _seasonController.clear();
        _episodeController.clear();
        _timestampController.clear();
        await _fetchLogs(); // Refresh the logs list
      } catch (e) {
        setState(() {
          _errorMessage = 'Error adding log: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteLog(String logId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.deleteLog(logId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log deleted successfully')),
      );
      await _fetchLogs(); // Refresh the logs list
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting log: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1D2B),
      appBar: AppBar(
        title: const Text('Save Media Episode you reached'),
        backgroundColor: const Color(0xFF252736),
        foregroundColor: const Color(0xFFEAEAEA),
      ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Section
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Log',
                              style: TextStyle(
                                color: Color(0xFFEAEAEA),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Tv Show Name',
                                labelStyle: const TextStyle(color: Color(0xFF92929D)),
                                filled: true,
                                fillColor: const Color(0xFF252736),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: Color(0xFFEAEAEA)),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the media name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _seasonController,
                              decoration: InputDecoration(
                                labelText: 'Season (optional)',
                                labelStyle: const TextStyle(color: Color(0xFF92929D)),
                                filled: true,
                                fillColor: const Color(0xFF252736),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: Color(0xFFEAEAEA)),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                                    return 'Season must be a valid number';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _episodeController,
                              decoration: InputDecoration(
                                labelText: 'Episode',
                                labelStyle: const TextStyle(color: Color(0xFF92929D)),
                                filled: true,
                                fillColor: const Color(0xFF252736),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: Color(0xFFEAEAEA)),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the episode number';
                                }
                                if (int.tryParse(value) == null || int.parse(value) < 0) {
                                  return 'Episode must be a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _timestampController,
                              decoration: InputDecoration(
                                labelText: 'Timestamp (optional, e.g., 00:45:00)',
                                labelStyle: const TextStyle(color: Color(0xFF92929D)),
                                filled: true,
                                fillColor: const Color(0xFF252736),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: Color(0xFFEAEAEA)),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final regex = RegExp(r'^\d{2}:\d{2}:\d{2}$');
                                  if (!regex.hasMatch(value)) {
                                    return 'Timestamp must be in HH:MM:SS format';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFEAEAEA),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _submitLog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF12CDC9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text(
                                      'Add Log',
                                      style: TextStyle(
                                        color: Color(0xFF1F1D2B),
                                        fontSize: 16,
                                      ),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Logs List Section
                    const Text(
                      'Episodes/Seasons you reached',
                      style: TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFEAEAEA),
                            ),
                          )
                        : _logs.isEmpty
                            ? const Text(
                                'No logs available',
                                style: TextStyle(
                                  color: Color(0xFFEAEAEA),
                                  fontSize: 16,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF252736).withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF12CDC9),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.history,
                                                    color: Color(0xFF12CDC9),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      log['name'],
                                                      style: const TextStyle(
                                                        color: Color(0xFFEAEAEA),
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Season: ${log['season'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  color: Color(0xFFEAEAEA),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'Episode: ${log['episode']}',
                                                style: const TextStyle(
                                                  color: Color(0xFFEAEAEA),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'Timestamp: ${log['timestamp'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  color: Color(0xFFEAEAEA),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'Logged: ${log['created_at'].substring(0, 10)}',
                                                style: const TextStyle(
                                                  color: Color(0xFF92929D),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Color(0xFFF72585),
                                          ),
                                          onPressed: () => _deleteLog(log['id']),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seasonController.dispose();
    _episodeController.dispose();
    _timestampController.dispose();
    super.dispose();
  }
}