// lib/services/report_downloader_web_helper.dart

import 'package:flutter/material.dart'; // For BuildContext
import 'package:mjifarm/services/report_downloader.dart'; // Import the abstract interface
import 'package:mjifarm/services/report_downloader_web.dart'; // Import the concrete web implementation

/// Web-specific implementation of the factory method.
ReportDownloader createReportDownloader(BuildContext context) => ReportDownloaderWeb(context: context);