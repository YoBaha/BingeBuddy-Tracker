import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bingebuddy/models/watchlist_item.dart';
import 'package:bingebuddy/models/watched_item.dart';
import 'package:flutter/material.dart'; 

class ExportUtils {
  // Request storage permission (only for Android API < 30)
  static Future<bool> _requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // Check Android version (Build.VERSION.SDK_INT equivalent)
      // For Android 11+ (API 30+), no permission needed for temporary files
      if (await _isAndroidVersionBelow30()) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showPermissionDeniedDialog(context);
          return false;
        }
        return true;
      }
      // For Android 11+, temporary files don't require permissions
      return true;
    }
    // iOS doesn't need explicit storage permission for temporary files
    return true;
  }

  // Check if Android version is below API 30 (Android 11)
  static Future<bool> _isAndroidVersionBelow30() async {
    if (Platform.isAndroid) {
      // Since device_info_plus is not in dependencies, assume API < 30 for testing
      // If needed, add device_info_plus to check SDK version
      return true; // Change to false for Android 11+ testing
    }
    return false;
  }

  // Show dialog if permission is denied
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252736),
        title: const Text('Permission Required', style: TextStyle(color: Color(0xFFEAEAEA))),
        content: const Text(
          'Storage permission is required to export files. Please enable it in app settings.',
          style: TextStyle(color: Color(0xFFEAEAEA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }

  // Export watchlist to CSV
  static Future<String> exportWatchlistToCsv(List<WatchlistItem> items, BuildContext context) async {
    if (!await _requestStoragePermission(context)) {
      throw Exception('Storage permission denied');
    }

    List<List<dynamic>> rows = [
      ['Title', 'Type', 'Priority', 'TMDB ID'],
      ...items.map((item) => [
            item.metadata['title'] ?? item.metadata['name'] ?? 'Unknown',
            item.itemType,
            item.priority,
            item.itemId,
          ]),
    ];

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/watchlist_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }

  // Export watched list to CSV
  static Future<String> exportWatchedToCsv(List<WatchedItem> items, BuildContext context) async {
    if (!await _requestStoragePermission(context)) {
      throw Exception('Storage permission denied');
    }

    List<List<dynamic>> rows = [
      ['Title', 'Type', 'Rating', 'TMDB ID'],
      ...items.map((item) => [
            item.metadata['title'] ?? item.metadata['name'] ?? 'Unknown',
            item.itemType,
            item.rating,
            item.itemId,
          ]),
    ];

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/watched_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }

  // Export watchlist to PDF
  static Future<String> exportWatchlistToPdf(List<WatchlistItem> items, BuildContext context) async {
    if (!await _requestStoragePermission(context)) {
      throw Exception('Storage permission denied');
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(16),
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('My BingeBuddy Watchlist', style: pw.TextStyle(fontSize: 24))),
          pw.Table.fromTextArray(
            headers: ['Title', 'Type', 'Priority', 'TMDB ID'],
            data: items.map((item) => [
                  item.metadata['title'] ?? item.metadata['name'] ?? 'Unknown',
                  item.itemType,
                  item.priority.toString(),
                  item.itemId,
                ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/watchlist_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  // Export watched list to PDF
  static Future<String> exportWatchedToPdf(List<WatchedItem> items, BuildContext context) async {
    if (!await _requestStoragePermission(context)) {
      throw Exception('Storage permission denied');
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(16),
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('My BingeBuddy Watched List', style: pw.TextStyle(fontSize: 24))),
          pw.Table.fromTextArray(
            headers: ['Title', 'Type', 'Rating', 'TMDB ID'],
            data: items.map((item) => [
                  item.metadata['title'] ?? item.metadata['name'] ?? 'Unknown',
                  item.itemType,
                  item.rating.toString(),
                  item.itemId,
                ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/watched_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  // Share file
  static Future<void> shareFile(String path, String subject) async {
    await Share.shareXFiles([XFile(path)], subject: subject);
  }
}