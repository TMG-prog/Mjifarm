// lib/services/report_downloader_web_impl.dart

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

import 'package:mjifarm/services/report_downloader.dart'; // Import the abstract class

class ReportDownloaderWeb implements ReportDownloader {
  final BuildContext context;

  ReportDownloaderWeb({required this.context});

  void _showSnackBar(String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Future<void> downloadReport(String fileName, String content) async {
    try {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);
      _showSnackBar('Report download initiated.', Colors.green);
    } catch (e) {
      print('Error downloading report for web: $e');
      _showSnackBar('Error downloading report for web: $e', Colors.red);
    }
  }
}

// Ensure there is NO function definition for _getReportDownloader here.