import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:smart_ar_navigation/app.dart';
import 'package:smart_ar_navigation/services/navigation_foreground_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind both status bar and navigation bar (edge-to-edge).
  // Each screen controls icon brightness via AnnotatedRegion.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await dotenv.load(fileName: '.env');
  NavigationForegroundService.initialize();
  // Register the IsolateNameServer port so sendDataToMain() messages
  // are received by addTaskDataCallback listeners in the main isolate.
  FlutterForegroundTask.initCommunicationPort();
  runApp(const SmartARNavigationApp());
}
