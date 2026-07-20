import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class NavigationForegroundService {
  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'smart_ar_nav_v3',
        channelName: 'Smart AR Navigation',
        channelDescription: 'Navigation is running',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
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

  static Future<bool> startService({
    required String destination,
    required String eta,
  }) async {
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Navigation Active',
      notificationText: 'Smart AR Navigate is running',
      notificationInitialRoute: '/ar-navigation',
      notificationButtons: [
        const NotificationButton(id: 'switch_off', text: 'Switch off'),
      ],
      callback: _startCallback,
    );
    if (result is ServiceRequestFailure) {
      debugPrint('Foreground service failed to start: ${result.error}');
      return false;
    }
    return true;
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

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'switch_off') {
      // Stop the foreground service directly from the task isolate — does
      // not need the main isolate event loop.
      FlutterForegroundTask.stopService();
      // Notify main isolate to clean up navigation state.
      FlutterForegroundTask.sendDataToMain('stop_navigation');
    }
  }

  @override
  void onNotificationPressed() {
    // Bring app to foreground when notification body is tapped.
    FlutterForegroundTask.launchApp('/ar-navigation');
  }
}
