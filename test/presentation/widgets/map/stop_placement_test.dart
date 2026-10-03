import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trancity/core/utils/map_utils.dart';
import 'package:trancity/presentation/widgets/map/stop_placement.dart';

/// Rua de teste em Chapecó, indo para o leste (~990 m).
const List<LatLng> _eastbound = <LatLng>[
  LatLng(-27.1, -52.62),
  LatLng(-27.1, -52.61),
];

/// Distância (m) entre [point] e a rua [_eastbound] (latitude -27.1).
double _metersFromRoad(LatLng point) =>
    MapUtils.distanceInKm(point, LatLng(-27.1, point.longitude)) * 1000;

void main() {
  group('MapUtils.offset', () {
    test('desloca a distância pedida no rumo pedido', () {
      const LatLng origin = LatLng(-27.1, -52.615);
      for (final double bearing in <double>[0, 45, 90, 180, 270]) {
        final LatLng moved = MapUtils.offset(origin, bearing, 10);
        final double meters = MapUtils.distanceInKm(origin, moved) * 1000;
        expect(meters, closeTo(10, 0.05));
        expect(MapUtils.bearing(origin, moved), closeTo(bearing % 360, 0.5));
      }
    });
  });

  group('StopPlacement.roadside', () {
    test('parada no meio da rua vai para a direita do sentido da linha', () {
      final LatLng placed =
          StopPlacement.roadside(const LatLng(-27.1, -52.615), _eastbound);
      // Indo para o leste, a direita é o sul.
      expect(placed.latitude, lessThan(-27.1));
      expect(_metersFromRoad(placed), closeTo(10, 0.1));
    });

    test('parada perto da rua continua do lado em que foi cadastrada', () {
      final LatLng north = MapUtils.offset(const LatLng(-27.1, -52.615), 0, 5);
      final LatLng placed = StopPlacement.roadside(north, _eastbound);
      expect(placed.latitude, greaterThan(-27.1));
      expect(_metersFromRoad(placed), closeTo(10, 0.1));
    });

    test('parada já na calçada não sai do lugar', () {
      final LatLng sidewalk =
          MapUtils.offset(const LatLng(-27.1, -52.615), 180, 15);
      expect(StopPlacement.roadside(sidewalk, _eastbound), sidewalk);
    });

    test('sem traçado, a parada fica na coordenada cadastrada', () {
      const LatLng stop = LatLng(-27.1, -52.615);
      expect(StopPlacement.roadside(stop, const <LatLng>[]), stop);
    });
  });
}
