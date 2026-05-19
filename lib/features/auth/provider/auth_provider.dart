import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/login_response.dart';
import '../repository/auth_repository_impl.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, LoginResponse?>(
  AuthNotifier.new,
);

final workspaceProvider = StateProvider<String?>((ref) => null);

class AuthNotifier extends AsyncNotifier<LoginResponse?> {
  @override
  Future<LoginResponse?> build() async {
    return ref.read(authRepositoryProvider).getSession();
  }

  Future<void> login(String email, String senha) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, senha),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(workspaceProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}
