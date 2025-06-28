// lib/services/report_downloader_stub.dart

import 'package:flutter/material.dart'; // Required for BuildContext

// IMPORTANT: Directly import the abstract class so the stub can return it if needed.
import 'package:mjifarm/services/report_downloader.dart';

/// Default implementation of ReportDownloader for unsupported platforms or as a fallback.
/// This function will be selected by the conditional import if no specific platform matches.
ReportDownloader _getReportDownloader(BuildContext context) => throw UnsupportedError(
    'Cannot create a ReportDownloader instance for the current platform. '
    'Ensure you are building for web or mobile, and that the platform-specific '
    'implementations are correctly defined and linked.'
  );