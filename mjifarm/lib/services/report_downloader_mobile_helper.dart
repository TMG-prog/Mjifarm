// lib/services/report_downloader_mobile_helper.dart

import 'package:flutter/material.dart'; // For BuildContext
import 'package:mjifarm/services/report_downloader.dart'; // Import the abstract interface
import 'package:mjifarm/services/report_downloader_mobile.dart'; // Import the concrete mobile implementation

/// Mobile-specific implementation of the factory method.
ReportDownloader createReportDownloader(BuildContext context) => ReportDownloaderMobile(context: context);