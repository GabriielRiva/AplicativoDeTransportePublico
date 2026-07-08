import '../../repositories/auth_repository.dart';

/// Encerra a sessão do usuário autenticado (RF16).
class LogoutUser {
  /// Cria o usecase com o repositório de autenticação.
  const LogoutUser(this._authRepository);

  final AuthRepository _authRepository;

  /// Executa o logout.
  Future<void> call() => _authRepository.logout();
}
