import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/data/models/trip_model.dart';
import 'package:trancity/domain/entities/enums/driver_status.dart';
import 'package:trancity/domain/entities/trip.dart';
import 'package:trancity/domain/usecases/passenger/watch_active_buses.dart';

Trip _trip(String id, DateTime? updatedAt) => Trip(
      id: id,
      driverId: id,
      busId: 'bus_1',
      lineId: 'line_101',
      startedAt: DateTime(2026),
      status: DriverStatus.tripStarted,
      currentLatitude: -27.1,
      currentLongitude: -52.6,
      updatedAt: updatedAt,
    );

void main() {
  group('WatchActiveBuses.withoutStale', () {
    final DateTime now = DateTime(2026, 10, 6, 12);

    test('remove ônibus sem posição nova há mais de 2 minutos', () {
      final List<Trip> fresh = WatchActiveBuses.withoutStale(
        <Trip>[
          _trip('ativo', now.subtract(const Duration(seconds: 5))),
          _trip('fantasma', now.subtract(const Duration(minutes: 3))),
        ],
        now,
      );
      expect(fresh.map((Trip trip) => trip.id), <String>['ativo']);
    });

    test('mantém trajetos ainda sem horário de atualização', () {
      final List<Trip> fresh =
          WatchActiveBuses.withoutStale(<Trip>[_trip('novo', null)], now);
      expect(fresh, hasLength(1));
    });
  });

  test('TripModel lê o horário da última atualização (updatedAt)', () {
    final TripModel trip = TripModel.fromJson('uid1', <String, dynamic>{
      'status': 'trip_started',
      'updatedAt': 1750000000000,
    });
    expect(
      trip.updatedAt,
      DateTime.fromMillisecondsSinceEpoch(1750000000000),
    );
  });
}
