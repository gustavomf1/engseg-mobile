import '../model/login_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(String email, String senha);
  Future<void> logout();
  Future<LoginResponse?> getSession();
}
