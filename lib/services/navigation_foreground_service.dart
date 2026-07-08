import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Top-level entry point for the foreground task isolate.
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_NavigationTaskHandler());
}

class _NavigationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  // 'Switch off' button tapped — tell the main isolate to stop navigation.
  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'switch_off') {
      FlutterForegroundTask.sendDataToMain('stop_navigation');
    }
  }
}

class NavigationForegroundService {
  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'smart_ar_navigation',
        channelName: 'Smart AR Navigation',
        channelDescription: 'Navigation is running',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> startService({
    required String destination,
    required String eta,
  }) async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Smart AR Navigate',
      notificationText: 'Running. Tap to open.',
      notificationInitialRoute: '/ar-navigation',
      notificationButtons: [
        NotificationButton(id: 'switch_off', text: 'Switch off'),
      ],
      callback: _startCallback,
    );
  }

  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }

  static Future<void> updateNotification({
    required String destination,
    required String eta,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Smart AR Navigate',
      notificationText: 'Running. Tap to open.',
    );
  }
}
