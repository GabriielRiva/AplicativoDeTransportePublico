import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/core/errors/app_exception.dart';
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
    when(() => userRepository.reserveCnh(any(), any()))
        .thenAnswer((_) async {});
    when(() => userRepository.releaseCnh(any())).thenAnswer((_) async {});
    when(() => authRepository.deleteCurrentUser()).thenAnswer((_) async {});
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
    verify(() => userRepository.reserveCnh('uid1', '12345678901')).called(1);
  });

  test('recusa CNH já cadastrada e desfaz a conta criada', () async {
    when(() => userRepository.reserveCnh(any(), any())).thenThrow(
      const ValidationException('Esta CNH já está cadastrada em outra conta.'),
    );

    await expectLater(
      registerUser(
        name: 'Gabriel Riva',
        email: 'gabriel@trancity.com',
        password: 'senha123',
        role: UserRole.driver,
        cnh: '12345678901',
      ),
      throwsA(isA<ValidationException>()),
    );

    verifyNever(() => userRepository.saveProfile(any()));
    verifyNever(() => userRepository.releaseCnh(any()));
    verify(() => authRepository.deleteCurrentUser()).called(1);
  });

  test('libera a CNH e exclui a conta se o perfil não for salvo', () async {
    when(() => userRepository.saveProfile(any())).thenThrow(
      const DatabaseException('Falha'),
    );

    await expectLater(
      registerUser(
        name: 'Gabriel Riva',
        email: 'gabriel@trancity.com',
        password: 'senha123',
        role: UserRole.driver,
        cnh: '12345678901',
      ),
      throwsA(isA<DatabaseException>()),
    );

    verify(() => userRepository.releaseCnh('12345678901')).called(1);
    verify(() => authRepository.deleteCurrentUser()).called(1);
  });

  test('normaliza o e-mail (sem espaços e minúsculo)', () async {
    final User user = await registerUser(
      name: 'Maria Silva',
      email: '  Maria@TranCity.com ',
      password: 'senha123',
      role: UserRole.passenger,
    );

    expect(user.email, 'maria@trancity.com');
    verify(
      () => authRepository.register(
        email: 'maria@trancity.com',
        password: 'senha123',
      ),
    ).called(1);
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
    verifyNever(() => userRepository.reserveCnh(any(), any()));
  });
}
