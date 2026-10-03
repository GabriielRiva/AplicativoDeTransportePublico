import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trancity/core/utils/map_utils.dart';
import 'package:trancity/presentation/widgets/map/stop_placement.dart';

/// Rua de teste em Chapecó, indo para o leste (~990 m).
const List<LatLng> _eastbound = <LatLng>[
  LatLng(-27.1, -52.62),
  LatLng(-27.1, -52.61),
];

/// Rua de teste indo para o norte (~1,1 km).
const List<LatLng> _northbound = <LatLng>[
  LatLng(-27.11, -52.615),
  LatLng(-27.1, -52.615),
];

/// Distância (m) entre [point] e a rua [_eastbound] (latitude -27.1).
double _metersFromRoad(LatLng point) =>
    MapUtils.distanceInKm(point, LatLng(-27.1, point.longitude)) * 1000;

/// Diferença (graus, 0 a 180) entre dois rumos.
double _angleBetween(double a, double b) =>
    (((a - b) % 360 + 540) % 360 - 180).abs();

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
    test('parada no meio da rua vai para a direita, de frente para a rua',
        () {
      final StopDisplay placed =
          StopPlacement.roadside(const LatLng(-27.1, -52.615), _eastbound);
      // Indo para o leste, a direita é o sul; o abrigo olha para o norte.
      expect(placed.position.latitude, lessThan(-27.1));
      expect(_metersFromRoad(placed.position), closeTo(10, 0.1));
      expect(_angleBetween(placed.facing, 0), lessThan(0.5));
    });

    test('rua indo para o norte: abrigo a leste, olhando para o oeste', () {
      final StopDisplay placed =
          StopPlacement.roadside(const LatLng(-27.105, -52.615), _northbound);
      expect(placed.position.longitude, greaterThan(-52.615));
      expect(_angleBetween(placed.facing, 270), lessThan(0.5));
    });

    test('parada perto da rua continua do lado em que foi cadastrada', () {
      final LatLng north = MapUtils.offset(const LatLng(-27.1, -52.615), 0, 5);
      final StopDisplay placed = StopPlacement.roadside(north, _eastbound);
      expect(placed.position.latitude, greaterThan(-27.1));
      expect(_metersFromRoad(placed.position), closeTo(10, 0.1));
      expect(_angleBetween(placed.facing, 180), lessThan(0.5));
    });

    test('parada já na calçada não sai do lugar e olha para a rua', () {
      final LatLng sidewalk =
          MapUtils.offset(const LatLng(-27.1, -52.615), 180, 15);
      final StopDisplay placed = StopPlacement.roadside(sidewalk, _eastbound);
      expect(placed.position, sidewalk);
      expect(_angleBetween(placed.facing, 0), lessThan(0.5));
    });

    test('sem traçado, a parada fica na coordenada cadastrada', () {
      const LatLng stop = LatLng(-27.1, -52.615);
      final StopDisplay placed =
          StopPlacement.roadside(stop, const <LatLng>[]);
      expect(placed.position, stop);
    });
  });
}
