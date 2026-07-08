import '../../repositories/auth_repository.dart';

/// Envia o e-mail de recuperação de senha (RF17).
class RecoverPassword {
  /// Cria o usecase com o repositório de autenticação.
  const RecoverPassword(this._authRepository);

  final AuthRepository _authRepository;

  /// Solicita a recuperação de senha para o [email] informado.
  Future<void> call(String email) =>
      _authRepository.recoverPassword(email.trim());
}
