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
import 'features/settings/presentation/app_lock_gate.dart';
import 'features/splash/presentation/splash_end.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefsFuture = SharedPreferences.getInstance();
  try {
    await Future.wait<void>([
      initFirebase(),
      initializeDateFormatting('ar'),
      localReminderService.init(),
    ]).timeout(const Duration(seconds: 8));
  } catch (_) {
    // Continue — login can still open; cloud features retry later.
  }

  late final SharedPreferences prefs;
  try {
    prefs = await prefsFuture.timeout(const Duration(seconds: 5));
  } catch (_) {
    prefs = await SharedPreferences.getInstance();
  }

  final database = LocalDatabase(prefs);
  await database.seedIfNeeded();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWith((ref) => prefs)],
      child: const A3trafApp(),
    ),
  );

  // ignore: unawaited_futures
  seedDebugTesters();
}

class A3trafApp extends ConsumerStatefulWidget {
  const A3trafApp({super.key});

  @override
  ConsumerState<A3trafApp> createState() => _A3trafAppState();
}

class _A3trafAppState extends ConsumerState<A3trafApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeHtmlSplash();
    });
  }

  @override
  Widget build(BuildContext context) {
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
      builder: (context, child) => AppLockGate(child: child ?? const SizedBox()),
    );
  }
}
