import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trancity/data/datasources/driver_remote_datasource.dart';
import 'package:trancity/data/models/trip_model.dart';
import 'package:trancity/data/repositories/driver_repository_impl.dart';
import 'package:trancity/domain/entities/enums/driver_status.dart';
import 'package:trancity/domain/entities/trip.dart';

class MockDriverRemoteDatasource extends Mock
    implements DriverRemoteDatasource {}

void main() {
  late MockDriverRemoteDatasource datasource;
  late DriverRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      TripModel(
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
    datasource = MockDriverRemoteDatasource();
    repository = DriverRepositoryImpl(datasource);
  });

  test('startTrip converte a entidade em TripModel e delega', () async {
    when(() => datasource.startTrip(any())).thenAnswer((_) async {});

    final Trip trip = Trip(
      id: 'uid1',
      driverId: 'uid1',
      busId: 'bus_1430',
      lineId: 'line_101',
      startedAt: DateTime(2026),
      status: DriverStatus.tripStarted,
      currentLatitude: -27.1004,
      currentLongitude: -52.6152,
    );

    await repository.startTrip(trip);

    final TripModel sent =
        verify(() => datasource.startTrip(captureAny())).captured.single
            as TripModel;
    expect(sent.driverId, 'uid1');
    expect(sent.lineId, 'line_101');
    expect(sent.status, DriverStatus.tripStarted);
  });

  test('sendLocation repassa as coordenadas ao datasource', () async {
    when(
      () => datasource.sendLocation(
        driverId: any(named: 'driverId'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async {});

    await repository.sendLocation(
      driverId: 'uid1',
      latitude: -27.1004,
      longitude: -52.6152,
    );

    verify(
      () => datasource.sendLocation(
        driverId: 'uid1',
        latitude: -27.1004,
        longitude: -52.6152,
      ),
    ).called(1);
  });
}
