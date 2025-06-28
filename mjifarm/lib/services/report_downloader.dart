// lib/services/report_downloader.dart

import 'package:flutter/material.dart'; // Required for BuildContext
// This imports the file that conditionally exports the createReportDownloader function.
import 'package:mjifarm/services/create_report_downloader.dart';

/// Abstract class defining the contract for report downloading.
abstract class ReportDownloader {
  /// Factory constructor to get the platform-specific implementation.
  /// It calls the 'createReportDownloader' function which is resolved
  /// at compile-time by the conditional export in 'create_report_downloader.dart'.
  factory ReportDownloader({required BuildContext context}) {
    // THIS LINE IS CRUCIAL: It must call createReportDownloader, NOT _getReportDownloader.
    return createReportDownloader(context);
  }

  Future<void> downloadReport(String fileName, String content);
}