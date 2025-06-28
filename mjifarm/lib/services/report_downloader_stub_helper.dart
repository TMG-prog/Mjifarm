// TODO Implement this library.
// lib/services/report_downloader_stub_helper.dart

import 'package:flutter/material.dart'; // For BuildContext
import 'package:mjifarm/services/report_downloader.dart'; // Import the abstract interface

/// Default implementation of the factory method for unsupported platforms.
ReportDownloader createReportDownloader(BuildContext context) => throw UnsupportedError(
    'Cannot create a ReportDownloader instance for the current platform. '
    'Ensure you are building for web or mobile, and that the platform-specific '
    'implementations are correctly defined and linked via create_report_downloader.dart.'
  );