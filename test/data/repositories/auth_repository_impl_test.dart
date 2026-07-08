import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/data/datasources/firebase_auth_datasource.dart';
import 'package:trancity/data/repositories/auth_repository_impl.dart';

class MockFirebaseAuthDatasource extends Mock
    implements FirebaseAuthDatasource {}

void main() {
  late MockFirebaseAuthDatasource datasource;
  late AuthRepositoryImpl repository;

  setUp(() {
    datasource = MockFirebaseAuthDatasource();
    repository = AuthRepositoryImpl(datasource);
  });

  test('login delega ao datasource e retorna o UID', () async {
    when(
      () => datasource.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => 'uid1');

    final String uid = await repository.login(
      email: 'gabriel@trancity.com',
      password: 'senha123',
    );

    expect(uid, 'uid1');
    verify(
      () => datasource.login(
        email: 'gabriel@trancity.com',
        password: 'senha123',
      ),
    ).called(1);
  });

  test('logout delega ao datasource', () async {
    when(() => datasource.logout()).thenAnswer((_) async {});
    await repository.logout();
    verify(() => datasource.logout()).called(1);
  });

  test('currentUid expõe o UID da sessão do datasource', () {
    when(() => datasource.currentUid).thenReturn('uid1');
    expect(repository.currentUid, 'uid1');
  });
}
