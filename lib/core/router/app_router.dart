import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_priests_screen.dart';
import '../../features/admin/presentation/church_form_screen.dart';
import '../../features/admin/presentation/churches_screen.dart';
import '../../features/admin/presentation/priest_form_screen.dart';
import '../../features/appointments/presentation/appointment_details_screen.dart';
import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/booking/presentation/booking_success_screen.dart';
import '../../features/booking/presentation/confirm_booking_screen.dart';
import '../../features/booking/presentation/select_slot_screen.dart';
import '../../features/church/presentation/church_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/info/presentation/conscience_exam_screen.dart';
import '../../features/info/presentation/guide_screens.dart';
import '../../features/info/presentation/info_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/priests/presentation/choose_father_screen.dart';
import '../../features/priests/presentation/priest_list_screen.dart';
import '../../features/care/presentation/assign_care_screen.dart';
import '../../features/care/presentation/priest_home_screen.dart';
import '../../features/care/presentation/spiritual_rule_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'transitions.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authControllerProvider) != null;
      final user = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final splash = location == '/splash';
      final authRoute = location == '/login' || location == '/signup';
      final chooseFather = location == '/choose-father';
      if (splash) return null;
      if (!loggedIn) {
        if (authRoute) return null;
        return '/login';
      }
      if (user?.needsFather == true && !chooseFather) {
        return '/choose-father';
      }
      if (authRoute) return '/home';
      if (location.startsWith('/admin') && user?.isAdmin != true) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const SignupScreen()),
      ),
      GoRoute(
        path: '/choose-father',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const ChooseFatherScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const HomeScreen()),
      ),
      GoRoute(
        path: '/priests',
        pageBuilder: (context, state) => sharedAxisPage(
          state: state,
          child: PriestListScreen(
            rescheduleId: state.uri.queryParameters['rescheduleId'],
          ),
        ),
      ),
      GoRoute(
        path: '/appointments',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const AppointmentsScreen()),
      ),
      GoRoute(
        path: '/booking/slot',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const SelectSlotScreen()),
      ),
      GoRoute(
        path: '/booking/confirm',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const ConfirmBookingScreen()),
      ),
      GoRoute(
        path: '/booking/success',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const BookingSuccessScreen()),
      ),
      GoRoute(
        path: '/appointment/:id',
        pageBuilder: (context, state) => sharedAxisPage(
          state: state,
          child: AppointmentDetailsScreen(
            appointmentId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/info',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const InfoScreen()),
      ),
      GoRoute(
        path: '/info/guide',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const ConfessionGuideScreen()),
      ),
      GoRoute(
        path: '/info/conscience',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const ConscienceExamScreen()),
      ),
      GoRoute(
        path: '/info/psalm',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const PsalmScreen()),
      ),
      GoRoute(
        path: '/info/fasts',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const FastsScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: '/rule',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const SpiritualRuleScreen()),
      ),
      GoRoute(
        path: '/priest/schedule',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const PriestScheduleScreen()),
      ),
      GoRoute(
        path: '/priest/overdue',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const PriestOverdueScreen()),
      ),
      GoRoute(
        path: '/priest/flock',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const PriestFlockScreen()),
      ),
      GoRoute(
        path: '/care/:userId',
        pageBuilder: (context, state) => sharedAxisPage(
          state: state,
          child: AssignCareScreen(userId: state.pathParameters['userId']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const AboutScreen()),
      ),
      GoRoute(
        path: '/contact',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const ContactScreen()),
      ),
      GoRoute(
        path: '/admin/churches',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const ChurchesScreen()),
      ),
      GoRoute(
        path: '/admin/churches/:churchId',
        pageBuilder: (context, state) => sharedAxisPage(
          state: state,
          child: ChurchFormScreen(churchId: state.pathParameters['churchId']),
        ),
      ),
      GoRoute(
        path: '/admin/priests',
        pageBuilder: (context, state) =>
            sharedAxisPage(state: state, child: const AdminPriestsScreen()),
      ),
      GoRoute(
        path: '/admin/priests/:priestId',
        pageBuilder: (context, state) => sharedAxisPage(
          state: state,
          child: PriestFormScreen(priestId: state.pathParameters['priestId']),
        ),
      ),
    ],
  );
});
