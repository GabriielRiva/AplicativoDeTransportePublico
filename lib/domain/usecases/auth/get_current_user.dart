import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';

/// Retorna o perfil do usuário com sessão ativa, ou nulo (RF03/RF20).
///
/// Usado pela Splash para decidir entre Login, Home do Passageiro
/// ou Home do Motorista.
class GetCurrentUser {
  /// Cria o usecase com os repositórios necessários.
  const GetCurrentUser(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  /// Busca o perfil da sessão atual; retorna nulo se não há sessão.
  Future<User?> call() async {
    final String? uid = _authRepository.currentUid;
    if (uid == null) return null;
    return _userRepository.getProfile(uid);
  }
}
