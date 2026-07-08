import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils.distanceInKm', () {
    test('distância entre pontos idênticos é zero', () {
      expect(
        GeoUtils.distanceInKm(-27.1004, -52.6152, -27.1004, -52.6152),
        0,
      );
    });

    test('0,01 grau de latitude equivale a ~1,11 km (Haversine)', () {
      final double distance =
          GeoUtils.distanceInKm(-27.1004, -52.6152, -27.1104, -52.6152);
      expect(distance, closeTo(1.11, 0.02));
    });
  });

  group('GeoUtils.estimateArrivalMinutes', () {
    test('retorna no mínimo 1 minuto para distâncias curtas', () {
      final int eta = GeoUtils.estimateArrivalMinutes(
        -27.1004,
        -52.6152,
        -27.1005,
        -52.6152,
      );
      expect(eta, greaterThanOrEqualTo(1));
    });

    test('estimativa cresce com a distância', () {
      final int near = GeoUtils.estimateArrivalMinutes(
        -27.1004,
        -52.6152,
        -27.1104,
        -52.6152,
      );
      final int far = GeoUtils.estimateArrivalMinutes(
        -27.1004,
        -52.6152,
        -27.2004,
        -52.6152,
      );
      expect(far, greaterThan(near));
    });
  });
}
