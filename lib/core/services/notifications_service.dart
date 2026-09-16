import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Centralise les notifications locales. Principe produit important :
/// AURAGOAL ne doit jamais culpabiliser (cahier des charges §1) — les
/// messages restent doux, jamais alarmistes ("Ne perds pas ta série !").
///
/// Note : flutter_local_notifications ne supporte pas le web. Toutes les
/// méthodes sont no-op sur cette plateforme pour ne pas casser les tests
/// effectués dans le navigateur pendant le développement.
class NotificationsService {
  NotificationsService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {
      // Fallback silencieux si la détection échoue — les rappels
      // utiliseront alors le fuseau par défaut du package timezone.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Un identifiant de notification stable dérivé de l'UUID de l'habitude,
  /// pour pouvoir la retrouver et l'annuler précisément plus tard.
  static int _notificationIdFor(String habitId) => habitId.hashCode & 0x7FFFFFFF;

  /// Programme un rappel doux ce soir (si l'heure n'est pas déjà passée)
  /// pour une habitude dont la série est encore active mais pas encore
  /// cochée aujourd'hui. Remplace tout rappel déjà programmé pour cette
  /// habitude.
  static Future<void> scheduleGentleStreakReminder({
    required String habitId,
    required String habitTitle,
    required int currentStreak,
    int hour = 20,
    int minute = 0,
  }) async {
    if (!_initialized) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledTime.isBefore(now)) {
      // L'heure est déjà passée pour aujourd'hui — pas de rappel pour
      // hier ou demain, on annule simplement (rien à faire ce soir).
      await cancelReminder(habitId);
      return;
    }

    final body = currentStreak > 0
        ? 'Ta série de $currentStreak jour${currentStreak > 1 ? 's' : ''} pour "$habitTitle" t\'attend — encore un petit geste aujourd\'hui ?'
        : 'Un petit moment pour "$habitTitle" aujourd\'hui ?';

    await _plugin.zonedSchedule(
      _notificationIdFor(habitId),
      'AURAGOAL',
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Rappels d\'habitudes',
          channelDescription: 'Rappels doux pour tes habitudes du jour',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Annule le rappel programmé pour une habitude — à appeler dès que
  /// l'utilisateur coche l'habitude, pour ne pas le déranger pour rien.
  static Future<void> cancelReminder(String habitId) async {
    if (!_initialized) return;
    await _plugin.cancel(_notificationIdFor(habitId));
  }
}
