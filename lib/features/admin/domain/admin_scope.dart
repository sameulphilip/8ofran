import '../../appointments/domain/appointment.dart';
import '../../auth/domain/app_user.dart';
import '../../priests/domain/priest.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import 'church.dart';

class AdminStats {
  const AdminStats({
    required this.members,
    required this.pendingBookings,
    required this.todayAppointments,
    required this.availablePriests,
  });

  final int members;
  final int pendingBookings;
  final int todayAppointments;
  final int availablePriests;
}

List<Priest> priestsForAdmin(AppUser actor, List<Priest> priests) {
  if (actor.isSuperAdmin) return List.unmodifiable(priests);
  return [
    for (final priest in priests)
      if (actor.managesPriest(priest.churchId)) priest,
  ];
}

List<Church> churchesForAdmin(AppUser actor, List<Church> churches) {
  if (actor.isSuperAdmin) return List.unmodifiable(churches);
  return [
    for (final church in churches)
      if (actor.managesChurch(church.id)) church,
  ];
}

List<AppUser> membersForAdmin(
  AppUser actor,
  List<AppUser> users,
  List<Priest> priests,
) {
  final members = [
    for (final user in users)
      if (user.role == UserRole.member) user,
  ];
  if (actor.isSuperAdmin) return members;
  final allowed = {
    for (final priest in priestsForAdmin(actor, priests)) priest.id,
  };
  return [
    for (final user in members)
      if (!user.hasFather || allowed.contains(user.fatherId)) user,
  ];
}

/// Super admin sees every account; stewards see their flock members only.
List<AppUser> accountsForAdmin(
  AppUser actor,
  List<AppUser> users,
  List<Priest> priests,
) {
  if (actor.isSuperAdmin) return List.unmodifiable(users);
  return membersForAdmin(actor, users, priests);
}

String roleLabelFor(AppUser user) {
  if (user.email.trim().toLowerCase() == AppConstants.adminEmail ||
      (user.isAdmin && !user.hasManagedChurch)) {
    return AppStrings.roleAdmin;
  }
  if (user.isSteward) return AppStrings.roleSteward;
  if (user.role == UserRole.priest) return AppStrings.rolePriest;
  if (user.isAdmin) return AppStrings.roleAdmin;
  return AppStrings.roleMember;
}

List<Priest> bookablePriests(List<Priest> priests, List<Church> churches) {
  return [
    for (final priest in priests)
      if (priest.isBookable(findChurch(churches, priest.churchId))) priest,
  ];
}

AdminStats buildAdminStats({
  required AppUser actor,
  required List<AppUser> users,
  required List<Appointment> appointments,
  required List<Priest> priests,
  required List<Church> churches,
  DateTime? now,
}) {
  final scopedPriests = priestsForAdmin(actor, priests);
  final scopedMembers = membersForAdmin(actor, users, priests);
  final priestIds = {for (final priest in scopedPriests) priest.id};
  final moment = now ?? DateTime.now();
  final today = DateTime(moment.year, moment.month, moment.day);
  final scopedAppointments = [
    for (final item in appointments)
      if (priestIds.contains(item.priestId)) item,
  ];
  return AdminStats(
    members: scopedMembers.length,
    pendingBookings: [
      for (final item in scopedAppointments)
        if (item.isPending) item,
    ].length,
    todayAppointments: [
      for (final item in scopedAppointments)
        if (item.isActive &&
            DateTime(
                  item.startsAt.year,
                  item.startsAt.month,
                  item.startsAt.day,
                ) ==
                today)
          item,
    ].length,
    availablePriests: bookablePriests(scopedPriests, churches).length,
  );
}

bool matchesMemberQuery(AppUser user, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return user.fullName.toLowerCase().contains(needle) ||
      user.email.toLowerCase().contains(needle) ||
      user.username.toLowerCase().contains(needle);
}
