import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    final repo = ref.watch(authRepositoryProvider);
    final sub = repo.authState().listen((user) {
      if (state?.id == user?.id &&
          state?.role == user?.role &&
          state?.fatherId == user?.fatherId) {
        return;
      }
      state = user;
    });
    ref.onDispose(sub.cancel);
    return repo.currentUser();
  }

  Future<void> login({
    required String identifier,
    required String password,
    required bool remember,
  }) async {
    state = await ref
        .read(authRepositoryProvider)
        .login(identifier: identifier, password: password, remember: remember);
  }

  Future<void> signup({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? fatherId,
  }) async {
    state = await ref
        .read(authRepositoryProvider)
        .signup(
          fullName: fullName,
          username: username,
          email: email,
          password: password,
          fatherId: fatherId,
        );
  }

  Future<void> setFather(String fatherId) async {
    state = await ref.read(authRepositoryProvider).setFather(fatherId);
  }

  Future<void> loginWithGoogle() async {
    state = await ref.read(authRepositoryProvider).loginWithGoogle();
  }

  Future<void> sendPasswordReset(String email) {
    return ref.read(authRepositoryProvider).sendPasswordReset(email);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
