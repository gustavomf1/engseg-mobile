import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/login_response.dart';
import '../model/workspace_state.dart';
import '../repository/auth_repository_impl.dart';
import '../../../core/notifications/fcm_provider.dart';
import '../../../core/network/auth_reset.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, LoginResponse?>(
  AuthNotifier.new,
);

final workspaceProvider = StateProvider<WorkspaceState?>((ref) => null);

class AuthNotifier extends AsyncNotifier<LoginResponse?> {
  @override
  Future<LoginResponse?> build() async {
    registerForceLogoutCallback(() => state = const AsyncData(null));
    return ref.read(authRepositoryProvider).getSession();
  }

  Future<void> login(String email, String senha) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, senha),
    );
    if (state.hasValue && state.value != null) {
      await ref.read(fcmServiceProvider).init(state.value!.id);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(workspaceProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}
