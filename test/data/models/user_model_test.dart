import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/data/models/user_model.dart';
import 'package:trancity/domain/entities/driver.dart';
import 'package:trancity/domain/entities/passenger.dart';
import 'package:trancity/domain/entities/user.dart';

void main() {
  group('UserModel.fromJson', () {
    test('materializa Driver quando role é driver (RF03)', () {
      final User user = UserModel.fromJson('uid1', <String, dynamic>{
        'name': 'Gabriel Riva',
        'email': 'gabriel@trancity.com',
        'role': 'driver',
        'cnh': '12345678901',
        'createdAt': 1750000000000,
      });

      expect(user, isA<Driver>());
      expect((user as Driver).cnh, '12345678901');
    });

    test('materializa Passenger quando role é passenger', () {
      final User user = UserModel.fromJson('uid2', <String, dynamic>{
        'name': 'Maria Silva',
        'email': 'maria@trancity.com',
        'role': 'passenger',
        'createdAt': 1750000000000,
        'favoriteLines': <String>['line_101'],
      });

      expect(user, isA<Passenger>());
      expect((user as Passenger).favoriteLineIds, contains('line_101'));
    });

    test('usa passenger como padrão para role desconhecida', () {
      final User user = UserModel.fromJson('uid3', <String, dynamic>{
        'name': 'X',
        'email': 'x@x.com',
        'role': 'unknown',
        'createdAt': 0,
      });
      expect(user, isA<Passenger>());
    });
  });

  group('UserModel.toJson', () {
    test('serializa Driver com cnh e role driver', () {
      final Driver driver = Driver(
        uid: 'uid1',
        name: 'Gabriel Riva',
        email: 'gabriel@trancity.com',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1750000000000),
        cnh: '12345678901',
      );

      final Map<String, dynamic> json = UserModel.toJson(driver);
      expect(json['role'], 'driver');
      expect(json['cnh'], '12345678901');
      expect(json['createdAt'], 1750000000000);
    });
  });
}
