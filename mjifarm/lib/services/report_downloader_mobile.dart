// lib/services/report_downloader_mobile_impl.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

import 'package:mjifarm/services/report_downloader.dart'; // Import the abstract class

class ReportDownloaderMobile implements ReportDownloader {
  final BuildContext context;

  ReportDownloaderMobile({required this.context});

  void _showSnackBar(String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Future<void> downloadReport(String fileName, String content) async {
    try {
      PermissionStatus status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar(
            'Storage permission denied. Cannot download report.', Colors.red);
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsString(content);

      _showSnackBar('Report downloaded to: ${file.path}', Colors.green);
      print("Report saved to: ${file.path}");

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        _showSnackBar('Failed to open report: ${result.message}', Colors.orange);
        print('Failed to open report: ${result.message}');
      }
    } catch (e) {
      print('Error downloading report for mobile: $e');
      _showSnackBar('Error downloading report: $e', Colors.red);
    }
  }
}

// Ensure there is NO function definition for _getReportDownloader here.