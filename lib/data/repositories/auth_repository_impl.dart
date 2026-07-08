import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Implementação de [AuthRepository] via Firebase Authentication.
final class AuthRepositoryImpl implements AuthRepository {
  /// Cria a implementação recebendo o datasource de autenticação.
  const AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  @override
  Stream<String?> authStateChanges() => _datasource.authStateChanges();

  @override
  String? get currentUid => _datasource.currentUid;

  @override
  Future<String> register({
    required String email,
    required String password,
  }) {
    return _datasource.register(email: email, password: password);
  }

  @override
  Future<String> login({required String email, required String password}) {
    return _datasource.login(email: email, password: password);
  }

  @override
  Future<void> logout() => _datasource.logout();

  @override
  Future<void> recoverPassword(String email) =>
      _datasource.recoverPassword(email);
}
