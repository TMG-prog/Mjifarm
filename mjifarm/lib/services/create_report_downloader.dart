// lib/services/create_report_downloader.dart

// This file conditionally exports the *definition* of the createReportDownloader function.
// The Dart compiler will pick one of these 'export' statements.
export 'package:mjifarm/services/report_downloader_stub_helper.dart' // Default/stub
    if (dart.library.html) 'package:mjifarm/services/report_downloader_web_helper.dart' // Web
    if (dart.library.io) 'package:mjifarm/services/report_downloader_mobile_helper.dart'; // Mobile