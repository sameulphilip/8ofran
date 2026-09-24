import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../appointments/domain/appointment.dart';

class LocalReminderService {
  LocalReminderService();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(AppConstants.cairoTz));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> scheduleAppointment(Appointment appointment) async {
    if (kIsWeb || !_ready) return;
    if (!appointment.remind ||
        appointment.status != AppointmentStatus.confirmed ||
        !appointment.isUpcoming) {
      await cancelAppointment(appointment);
      return;
    }
    await _scheduleLead(appointment, days: 2);
    await _scheduleLead(appointment, days: 1);
  }

  Future<void> cancelAppointment(Appointment appointment) async {
    if (kIsWeb || !_ready) return;
    for (final days in AppConstants.reminderLeadDays) {
      await _plugin.cancel(id: _reminderId(appointment, days));
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
  }

  int _reminderId(Appointment appointment, int days) {
    return appointment.id.hashCode.abs() % 100000000 + days;
  }

  Future<void> _scheduleLead(Appointment appointment, {required int days}) async {
    final when = appointment.startsAt.subtract(Duration(days: days));
    if (!when.isAfter(DateTime.now())) return;
    final id = _reminderId(appointment, days);
    await _plugin.zonedSchedule(
      id: id,
      title: days == 2
          ? AppStrings.reminderTwoDaysTitle
          : AppStrings.reminderOneDayTitle,
      body: AppStrings.reminderAppointmentBody,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ghofran_reminders',
          AppStrings.reminderChannelName,
          channelDescription: AppStrings.reminderChannelBody,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

final localReminderService = LocalReminderService();
