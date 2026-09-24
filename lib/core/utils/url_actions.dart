import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class UrlActions {
  UrlActions._();

  static Future<void> openMap([String? query]) {
    final search = (query != null && query.trim().isNotEmpty)
        ? query.trim()
        : AppConstants.mapsQuery;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(search)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> callSupport() {
    return callPhone(AppConstants.supportPhoneE164);
  }

  static Future<void> callPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return Future.value();
    return launchUrl(Uri.parse('tel:$digits'));
  }

  static Future<void> emailSupport() {
    return launchUrl(Uri.parse('mailto:${AppConstants.supportEmail}'));
  }

  static Future<void> openStudio() {
    return launchUrl(
      Uri.parse(AppConstants.studioUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> whatsAppSupport() {
    final uri = Uri.parse(
      'https://wa.me/${AppConstants.supportPhoneE164.replaceAll('+', '')}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> addToCalendar({
    required DateTime startsAt,
    required String priestName,
    String? location,
    int slotMinutes = AppConstants.slotMinutes,
  }) {
    final end = startsAt.add(Duration(minutes: slotMinutes));
    final place = (location != null && location.trim().isNotEmpty)
        ? location.trim()
        : AppStrings.supportAddress;
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent('موعد مع $priestName')}'
      '&dates=${_googleStamp(startsAt)}/${_googleStamp(end)}'
      '&details=${Uri.encodeComponent(AppStrings.appName)}'
      '&location=${Uri.encodeComponent(place)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _googleStamp(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}00Z';
  }
}
