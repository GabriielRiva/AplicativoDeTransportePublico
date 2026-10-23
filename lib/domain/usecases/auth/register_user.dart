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
///
/// Unicidade:
/// - E-mail: o Firebase Authentication não cria duas contas com o mesmo
///   e-mail ("Este e-mail já está cadastrado."). O e-mail é normalizado
///   (sem espaços, minúsculo) para o perfil gravar o mesmo valor da conta.
/// - CNH: reservada em cnhs/{cnh}; as regras do banco recusam uma CNH que
///   já pertence a outra conta.
///
/// Se qualquer etapa depois da criação da conta falhar, o cadastro é
/// desfeito (CNH liberada e conta excluída). Assim o e-mail não fica preso
/// numa conta sem perfil e o usuário pode tentar de novo.
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
    final String normalizedEmail = email.trim().toLowerCase();
    final String driverCnh = (cnh ?? '').trim();

    final String uid = await _authRepository.register(
      email: normalizedEmail,
      password: password,
    );

    final DateTime now = DateTime.now();
    final User user = role == UserRole.driver
        ? Driver(
            uid: uid,
            name: name.trim(),
            email: normalizedEmail,
            createdAt: now,
            cnh: driverCnh,
          )
        : Passenger(
            uid: uid,
            name: name.trim(),
            email: normalizedEmail,
            createdAt: now,
          );

    bool cnhReserved = false;
    try {
      if (role == UserRole.driver) {
        await _userRepository.reserveCnh(uid, driverCnh);
        cnhReserved = true;
      }
      await _userRepository.saveProfile(user);
    } catch (_) {
      // Desfaz na ordem inversa: a CNH só pode ser liberada enquanto a
      // conta ainda existe (as regras exigem o dono autenticado).
      if (cnhReserved) await _userRepository.releaseCnh(driverCnh);
      await _authRepository.deleteCurrentUser();
      rethrow;
    }
    return user;
  }
}
