import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/core/errors/app_exception.dart';
import 'package:trancity/domain/repositories/driver_repository.dart';
import 'package:trancity/domain/usecases/driver/send_location.dart';

class MockDriverRepository extends Mock implements DriverRepository {}

void main() {
  late MockDriverRepository repository;
  late SendLocation sendLocation;

  setUp(() {
    repository = MockDriverRepository();
    sendLocation = SendLocation(repository);
  });

  test('rejeita coordenadas fora do intervalo válido', () {
    expect(
      () => sendLocation(driverId: 'uid1', latitude: 91, longitude: 0),
      throwsA(isA<LocationException>()),
    );
    expect(
      () => sendLocation(driverId: 'uid1', latitude: 0, longitude: 181),
      throwsA(isA<LocationException>()),
    );
  });

  test('transmite coordenadas válidas ao repositório (RF06)', () async {
    when(
      () => repository.sendLocation(
        driverId: any(named: 'driverId'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async {});

    await sendLocation(
      driverId: 'uid1',
      latitude: -27.1004,
      longitude: -52.6152,
    );

    verify(
      () => repository.sendLocation(
        driverId: 'uid1',
        latitude: -27.1004,
        longitude: -52.6152,
      ),
    ).called(1);
  });
}
