import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../priests/data/priest_repository.dart';
import 'booking_controller.dart';

void openMemberBooking(
  BuildContext context,
  WidgetRef ref, {
  String? rescheduleId,
  bool replace = false,
}) {
  final user = ref.read(authControllerProvider);
  if (user == null || user.isPriest || user.isAdmin) return;
  if (!user.hasFather) {
    context.push('/choose-father');
    return;
  }
  final priest = ref.read(priestRepositoryProvider).byId(user.fatherId!);
  if (priest == null || !priest.isAvailable) {
    context.push('/choose-father');
    return;
  }
  ref
      .read(bookingControllerProvider.notifier)
      .start(priest: priest, rescheduleId: rescheduleId);
  if (replace) {
    context.go('/booking/slot');
  } else {
    context.push('/booking/slot');
  }
}
