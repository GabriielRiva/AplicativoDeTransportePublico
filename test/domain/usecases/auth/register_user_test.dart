import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/domain/entities/driver.dart';
import 'package:trancity/domain/entities/enums/user_role.dart';
import 'package:trancity/domain/entities/passenger.dart';
import 'package:trancity/domain/entities/user.dart';
import 'package:trancity/domain/repositories/auth_repository.dart';
import 'package:trancity/domain/repositories/user_repository.dart';
import 'package:trancity/domain/usecases/auth/register_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockUserRepository userRepository;
  late RegisterUser registerUser;

  setUpAll(() {
    registerFallbackValue(
      Passenger(
        uid: '',
        name: '',
        email: '',
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    authRepository = MockAuthRepository();
    userRepository = MockUserRepository();
    registerUser = RegisterUser(authRepository, userRepository);

    when(
      () => authRepository.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => 'uid1');
    when(() => userRepository.saveProfile(any()))
        .thenAnswer((_) async {});
  });

  test('cadastra motorista com CNH e perfil driver (RF01)', () async {
    final User user = await registerUser(
      name: 'Gabriel Riva',
      email: 'gabriel@trancity.com',
      password: 'senha123',
      role: UserRole.driver,
      cnh: '12345678901',
    );

    expect(user, isA<Driver>());
    expect((user as Driver).cnh, '12345678901');
    expect(user.uid, 'uid1');

    final User saved =
        verify(() => userRepository.saveProfile(captureAny()))
            .captured
            .single as User;
    expect(saved, isA<Driver>());
  });

  test('cadastra passageiro sem CNH (RF01)', () async {
    final User user = await registerUser(
      name: 'Maria Silva',
      email: 'maria@trancity.com',
      password: 'senha123',
      role: UserRole.passenger,
    );

    expect(user, isA<Passenger>());
    expect(user.role, UserRole.passenger);
  });
}
