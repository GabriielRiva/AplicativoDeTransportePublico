import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';

/// Autentica o usuário por e-mail e senha (RF02) e carrega seu perfil,
/// permitindo o redirecionamento por perfil após o login (RF03).
class LoginUser {
  /// Cria o usecase com os repositórios necessários.
  const LoginUser(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  /// Executa o login e retorna o perfil do usuário autenticado.
  Future<User> call({required String email, required String password}) async {
    final String uid = await _authRepository.login(
      email: email.trim(),
      password: password,
    );
    return _userRepository.getProfile(uid);
  }
}
