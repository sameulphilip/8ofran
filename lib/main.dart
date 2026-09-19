import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_strings.dart';
import 'core/data/local_database.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/tester_seed.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/care/data/local_reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  await localReminderService.init();
  await initializeDateFormatting('ar');
  final prefs = await SharedPreferences.getInstance();
  final database = LocalDatabase(prefs);
  await database.seedIfNeeded();
  await seedDebugTesters();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWith((ref) => prefs)],
      child: const A3trafApp(),
    ),
  );
}

class A3trafApp extends ConsumerWidget {
  const A3trafApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
