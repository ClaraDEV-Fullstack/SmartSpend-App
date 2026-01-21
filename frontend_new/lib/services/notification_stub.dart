// lib/services/notification_stub.dart
// Stub file for web platform

class FlutterLocalNotificationsPlugin {
  Future<void> initialize(dynamic settings, {Function? onDidReceiveNotificationResponse}) async {}
  Future<void> show(int id, String? title, String? body, dynamic details, {String? payload}) async {}
  Future<void> cancelAll() async {}
  T? resolvePlatformSpecificImplementation<T>() => null;
}

class AndroidInitializationSettings {
  const AndroidInitializationSettings(String icon);
}

class DarwinInitializationSettings {
  const DarwinInitializationSettings({
    bool requestAlertPermission = false,
    bool requestBadgePermission = false,
    bool requestSoundPermission = false,
  });
}

class InitializationSettings {
  const InitializationSettings({dynamic android, dynamic iOS});
}

class AndroidNotificationDetails {
  const AndroidNotificationDetails(
      String channelId,
      String channelName, {
        String? channelDescription,
        dynamic importance,
        dynamic priority,
        bool showWhen = true,
      });
}

class DarwinNotificationDetails {
  const DarwinNotificationDetails({
    bool presentAlert = false,
    bool presentBadge = false,
    bool presentSound = false,
  });
}

class NotificationDetails {
  const NotificationDetails({dynamic android, dynamic iOS});
}

class NotificationResponse {
  final String? payload;
  NotificationResponse({this.payload});
}

class Importance {
  static const high = Importance._();
  static const defaultImportance = Importance._();
  const Importance._();
}

class Priority {
  static const high = Priority._();
  static const defaultPriority = Priority._();
  const Priority._();
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<bool?> requestNotificationsPermission() async => false;
}

class IOSFlutterLocalNotificationsPlugin {
  Future<bool?> requestPermissions({bool alert = false, bool badge = false, bool sound = false}) async => false;
}