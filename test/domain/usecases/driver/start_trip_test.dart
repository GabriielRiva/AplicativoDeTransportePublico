import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/core/errors/app_exception.dart';
import 'package:trancity/core/network/network_info.dart';
import 'package:trancity/domain/entities/enums/driver_status.dart';
import 'package:trancity/domain/entities/trip.dart';
import 'package:trancity/domain/repositories/driver_repository.dart';
import 'package:trancity/domain/usecases/driver/start_trip.dart';

class MockDriverRepository extends Mock implements DriverRepository {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockDriverRepository driverRepository;
  late MockNetworkInfo networkInfo;
  late StartTrip startTrip;

  setUpAll(() {
    registerFallbackValue(
      Trip(
        id: '',
        driverId: '',
        busId: '',
        lineId: '',
        startedAt: DateTime(2026),
        status: DriverStatus.tripStarted,
        currentLatitude: 0,
        currentLongitude: 0,
      ),
    );
  });

  setUp(() {
    driverRepository = MockDriverRepository();
    networkInfo = MockNetworkInfo();
    startTrip = StartTrip(driverRepository, networkInfo);
  });

  test('lança ValidationException sem linha selecionada (RF04)', () {
    expect(
      () => startTrip(
        driverId: 'uid1',
        lineId: '',
        busId: 'bus_1430',
        initialLatitude: -27.1,
        initialLongitude: -52.6,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('lança ValidationException sem ônibus selecionado (RF04)', () {
    expect(
      () => startTrip(
        driverId: 'uid1',
        lineId: 'line_101',
        busId: '',
        initialLatitude: -27.1,
        initialLongitude: -52.6,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('lança NetworkException sem conexão com a internet', () {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    expect(
      () => startTrip(
        driverId: 'uid1',
        lineId: 'line_101',
        busId: 'bus_1430',
        initialLatitude: -27.1,
        initialLongitude: -52.6,
      ),
      throwsA(isA<NetworkException>()),
    );
  });

  test('grava o trajeto com status trip_started (RF04)', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => driverRepository.startTrip(any()))
        .thenAnswer((_) async {});

    final Trip trip = await startTrip(
      driverId: 'uid1',
      lineId: 'line_101',
      busId: 'bus_1430',
      initialLatitude: -27.1004,
      initialLongitude: -52.6152,
    );

    expect(trip.status, DriverStatus.tripStarted);
    expect(trip.id, 'uid1');
    expect(trip.currentLatitude, -27.1004);
    verify(() => driverRepository.startTrip(any())).called(1);
  });
}
