import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class NavigationForegroundService {
  static Future<void> startService({
    required String destination,
    required String eta,
  }) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'smart_ar_navigation',
        channelName: 'Smart AR Navigation',
        channelDescription: 'Navigation is running',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      notificationTitle: 'Navigating to $destination',
      notificationText: 'ETA: $eta',
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
      notificationTitle: 'Navigating to $destination',
      notificationText: 'ETA: $eta',
    );
  }
}
