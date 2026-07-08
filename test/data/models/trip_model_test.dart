import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/data/models/trip_model.dart';
import 'package:trancity/domain/entities/enums/driver_status.dart';

void main() {
  group('TripModel.fromJson', () {
    test('interpreta o nó drivers/{uid} como trajeto ativo', () {
      final TripModel trip = TripModel.fromJson('uid1', <String, dynamic>{
        'busId': 'bus_1430',
        'lineId': 'line_101',
        'status': 'trip_started',
        'latitude': -27.1004,
        'longitude': -52.6152,
        'startedAt': 1750000000000,
      });

      expect(trip.id, 'uid1');
      expect(trip.driverId, 'uid1');
      expect(trip.status, DriverStatus.tripStarted);
      expect(trip.status.isActive, isTrue);
      expect(trip.currentLatitude, -27.1004);
      expect(trip.finishedAt, isNull);
    });

    test('trajeto encerrado não é considerado ativo', () {
      final TripModel trip = TripModel.fromJson('uid1', <String, dynamic>{
        'status': 'trip_finished',
        'finishedAt': 1750000500000,
      });

      expect(trip.status, DriverStatus.tripFinished);
      expect(trip.status.isActive, isFalse);
      expect(trip.finishedAt, isNotNull);
    });
  });

  group('TripModel.toJson', () {
    test('grava latitude/longitude nas chaves do FIREBASE_SCHEMA', () {
      final TripModel trip = TripModel(
        id: 'uid1',
        driverId: 'uid1',
        busId: 'bus_1430',
        lineId: 'line_101',
        startedAt: DateTime.fromMillisecondsSinceEpoch(1750000000000),
        status: DriverStatus.tripStarted,
        currentLatitude: -27.1004,
        currentLongitude: -52.6152,
      );

      final Map<String, dynamic> json = trip.toJson();
      expect(json['latitude'], -27.1004);
      expect(json['longitude'], -52.6152);
      expect(json['status'], 'trip_started');
      expect(json.containsKey('finishedAt'), isFalse);
    });
  });
}
