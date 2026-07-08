import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/data/models/driver_model.dart';
import 'package:trancity/domain/entities/enums/driver_status.dart';

void main() {
  group('DriverModel', () {
    test('fromJson lê status do FIREBASE_SCHEMA (trip_started)', () {
      final DriverModel driver =
          DriverModel.fromJson('uid1', <String, dynamic>{
        'name': 'Gabriel Riva',
        'email': 'gabriel@trancity.com',
        'cnh': '12345678901',
        'status': 'trip_started',
        'lineId': 'line_101',
        'busId': 'bus_1430',
        'createdAt': 1750000000000,
      });

      expect(driver.status, DriverStatus.tripStarted);
      expect(driver.lineId, 'line_101');
      expect(driver.busId, 'bus_1430');
      expect(driver.cnh, '12345678901');
    });

    test('toJson grava apenas os campos do perfil (nó users/)', () {
      final DriverModel driver = DriverModel(
        uid: 'uid1',
        name: 'Gabriel Riva',
        email: 'gabriel@trancity.com',
        cnh: '12345678901',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1750000000000),
      );

      final Map<String, dynamic> json = driver.toJson();

      expect(json['role'], 'driver');
      expect(json['cnh'], '12345678901');
      // Localização e trajeto pertencem ao nó drivers/, nunca ao perfil.
      expect(json.containsKey('latitude'), isFalse);
      expect(json.containsKey('longitude'), isFalse);
      expect(json.containsKey('status'), isFalse);
    });
  });
}
