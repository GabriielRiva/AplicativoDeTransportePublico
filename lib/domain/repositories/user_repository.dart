import '../entities/user.dart';

/// Contrato de perfis de usuário (nó users/ do Realtime Database).
abstract interface class UserRepository {
  /// Persiste o perfil do usuário recém-cadastrado.
  ///
  /// Aceita [User], [Driver] ou [Passenger]; os campos específicos de
  /// cada perfil são gravados conforme o tipo concreto.
  Future<void> saveProfile(User user);

  /// Busca o perfil pelo [uid], retornando [Driver] ou [Passenger]
  /// conforme o campo role armazenado.
  Future<User> getProfile(String uid);

  /// Atualiza a lista de linhas favoritas do passageiro.
  Future<void> updateFavoriteLines(String uid, List<String> lineIds);
}
