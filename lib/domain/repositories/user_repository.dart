import '../entities/user.dart';

/// Contrato de perfis de usuário (nó users/ do Realtime Database).
abstract interface class UserRepository {
  /// Persiste o perfil do usuário recém-cadastrado.
  ///
  /// Aceita [User], [Driver] ou [Passenger]; os campos específicos de
  /// cada perfil são gravados conforme o tipo concreto.
  Future<void> saveProfile(User user);

  /// Reserva a [cnh] para o motorista [uid]. Lança ValidationException
  /// se a CNH já estiver cadastrada em outra conta.
  Future<void> reserveCnh(String uid, String cnh);

  /// Libera uma CNH reservada (usado para desfazer um cadastro que falhou).
  Future<void> releaseCnh(String cnh);

  /// Busca o perfil pelo [uid], retornando [Driver] ou [Passenger]
  /// conforme o campo role armazenado.
  Future<User> getProfile(String uid);

  /// Atualiza a lista de linhas favoritas do passageiro.
  Future<void> updateFavoriteLines(String uid, List<String> lineIds);
}
