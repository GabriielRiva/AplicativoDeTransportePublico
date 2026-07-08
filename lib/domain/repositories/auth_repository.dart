/// Contrato de autenticação (Firebase Authentication).
abstract interface class AuthRepository {
  /// Stream com o UID do usuário autenticado (nulo quando deslogado).
  Stream<String?> authStateChanges();

  /// UID do usuário atualmente autenticado, ou nulo.
  String? get currentUid;

  /// Cria uma conta com e-mail e senha e retorna o UID gerado.
  Future<String> register({required String email, required String password});

  /// Autentica o usuário e retorna seu UID.
  Future<String> login({required String email, required String password});

  /// Encerra a sessão do usuário autenticado.
  Future<void> logout();

  /// Envia o e-mail de recuperação de senha.
  Future<void> recoverPassword(String email);
}
