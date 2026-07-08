import '../../entities/driver.dart';
import '../../entities/enums/user_role.dart';
import '../../entities/passenger.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';

/// Cadastra um novo usuário no sistema (RF01).
///
/// Cria a conta no Firebase Authentication e persiste o perfil
/// correspondente (motorista ou passageiro) no Realtime Database.
class RegisterUser {
  /// Cria o usecase com os repositórios necessários.
  const RegisterUser(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  /// Executa o cadastro e retorna o perfil criado.
  ///
  /// Para [UserRole.driver] o campo [cnh] é obrigatório.
  Future<User> call({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? cnh,
  }) async {
    final String uid = await _authRepository.register(
      email: email.trim(),
      password: password,
    );

    final DateTime now = DateTime.now();
    final User user = role == UserRole.driver
        ? Driver(
            uid: uid,
            name: name.trim(),
            email: email.trim(),
            createdAt: now,
            cnh: (cnh ?? '').trim(),
          )
        : Passenger(
            uid: uid,
            name: name.trim(),
            email: email.trim(),
            createdAt: now,
          );

    await _userRepository.saveProfile(user);
    return user;
  }
}
