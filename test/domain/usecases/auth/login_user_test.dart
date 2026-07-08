import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/domain/entities/passenger.dart';
import 'package:trancity/domain/entities/user.dart';
import 'package:trancity/domain/repositories/auth_repository.dart';
import 'package:trancity/domain/repositories/user_repository.dart';
import 'package:trancity/domain/usecases/auth/login_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late LoginUser loginUser;

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    loginUser = LoginUser(authRepository, userRepository);
  });

  test('autentica e retorna o perfil do usuário (RF02/RF03)', () async {
    final Passenger passenger = Passenger(
      uid: 'uid1',
      name: 'Maria Silva',
      email: 'maria@trancity.com',
      createdAt: DateTime(2026),
    );

    when(
      () => authRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => 'uid1');
    when(() => userRepository.getProfile('uid1'))
        .thenAnswer((_) async => passenger);

    final User user = await loginUser(
      email: '  maria@trancity.com  ',
      password: 'senha123',
    );

    expect(user, passenger);
    // O e-mail deve ser normalizado (trim) antes da autenticação.
    verify(
      () => authRepository.login(
        email: 'maria@trancity.com',
        password: 'senha123',
      ),
    ).called(1);
    verify(() => userRepository.getProfile('uid1')).called(1);
  });
}
