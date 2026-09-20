import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class UrlActions {
  UrlActions._();

  static Future<void> openMap() {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(AppConstants.mapsQuery)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> callSupport() {
    return launchUrl(Uri.parse('tel:${AppConstants.supportPhoneE164}'));
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
  }) {
    final end = startsAt.add(const Duration(minutes: AppConstants.slotMinutes));
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent('موعد مع $priestName')}'
      '&dates=${_googleStamp(startsAt)}/${_googleStamp(end)}'
      '&details=${Uri.encodeComponent(AppStrings.appName)}'
      '&location=${Uri.encodeComponent(AppStrings.supportAddress)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _googleStamp(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}00Z';
  }
}
