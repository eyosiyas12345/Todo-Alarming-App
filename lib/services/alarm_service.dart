import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for background alarm scheduling and audio playback.
class AlarmService {
  AlarmService._internal();
  static final AlarmService instance = AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  VoidCallback? onAlarmTriggered;

  static const String _channelId = 'task_alarm_channel';
  static const String _channelName = 'Task Alarms';
  static const String _channelDesc = 'Offline native alarm alerts for scheduled tasks';

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        playAlarmSound();
        onAlarmTriggered?.call();
      },
    );

    await _createNotificationChannel();
    await _configureAudioPlayer();
  }

  Future<void> _createNotificationChannel() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  Future<void> _configureAudioPlayer() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
    });
  }

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    String? description,
    required DateTime scheduledTime,
  }) async {
    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm.wav',
    );

    const linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: (description != null && description.isNotEmpty)
          ? description
          : 'Task alarm ringing!',
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAlarm(int id) async {
    await _notifications.cancel(id: id);
  }

  Future<void> playAlarmSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/alarm.wav'));
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing alarm audio: $e');
    }
  }

  Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping alarm audio: $e');
    }
  }
}
