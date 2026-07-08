import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

/// Implementação de [UserRepository] via Realtime Database.
final class UserRepositoryImpl implements UserRepository {
  /// Cria a implementação recebendo o datasource de usuários.
  const UserRepositoryImpl(this._datasource);

  final UserRemoteDatasource _datasource;

  @override
  Future<void> saveProfile(User user) => _datasource.saveProfile(user);

  @override
  Future<User> getProfile(String uid) => _datasource.getProfile(uid);

  @override
  Future<void> updateFavoriteLines(String uid, List<String> lineIds) =>
      _datasource.updateFavoriteLines(uid, lineIds);
}
