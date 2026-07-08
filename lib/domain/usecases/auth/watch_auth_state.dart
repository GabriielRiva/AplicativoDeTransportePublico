import '../../repositories/auth_repository.dart';

/// Observa o estado da sessão do usuário (RF20 — Controle de Sessão).
class WatchAuthState {
  /// Cria o usecase com o repositório de autenticação.
  const WatchAuthState(this._authRepository);

  final AuthRepository _authRepository;

  /// Stream com o UID autenticado, ou nulo quando a sessão encerra.
  Stream<String?> call() => _authRepository.authStateChanges();
}
