import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trancity/core/utils/map_utils.dart';
import 'package:trancity/domain/entities/stop.dart';
import 'package:trancity/presentation/widgets/map/route_progress.dart';
import 'package:trancity/presentation/widgets/map/route_stops.dart';

/// Rua reta indo para o leste, com um ponto a cada ~99 m (índices 0..20).
final List<LatLng> _straight = <LatLng>[
  for (int i = 0; i <= 20; i++) LatLng(-27.1, -52.62 + i * 0.001),
];

/// Linha circular: ida para o leste (0..20) e volta pela mesma rua, ~1 m
/// ao norte (21..40), terminando no início.
final List<LatLng> _loop = <LatLng>[
  for (int i = 0; i <= 20; i++) LatLng(-27.1, -52.62 + i * 0.001),
  for (int k = 1; k <= 20; k++) LatLng(-27.09999, -52.60 - k * 0.001),
];

Stop _stop(String id, int order, LatLng at) => Stop(
      id: id,
      lineId: 'line_test',
      name: 'Parada $id',
      latitude: at.latitude,
      longitude: at.longitude,
      order: order,
    );

/// Distância (m) de um trecho entre dois pontos vizinhos da rota.
final double _segment =
    MapUtils.distanceInKm(_straight[0], _straight[1]) * 1000;

/// Distância (m) do início da rota até o ponto [index] da [route].
double _metersAtIndex(List<LatLng> route, int index) {
  double meters = 0;
  for (int i = 1; i <= index; i++) {
    meters += MapUtils.distanceInKm(route[i - 1], route[i]) * 1000;
  }
  return meters;
}

void main() {
  group('RouteStops', () {
    final List<Stop> stops = <Stop>[
      // Fora de ordem de propósito: a ordem da linha é o campo order.
      _stop('c', 3, _straight[15]),
      _stop('a', 1, _straight[5]),
      _stop('b', 2, _straight[10]),
    ];

    test('próxima parada é a seguinte à frente, com a distância pela rota',
        () {
      final RouteStops routeStops = RouteStops(_straight, stops);
      final StopAhead? next =
          routeStops.nextStop(_metersAtIndex(_straight, 7));
      expect(next?.stop.id, 'b');
      expect(next!.meters, closeTo(3 * _segment, 1));
    });

    test('parada em que o ônibus está agora não conta como próxima', () {
      final RouteStops routeStops = RouteStops(_straight, stops);
      // 20 m antes da parada "b" (dentro do raio de chegada).
      final StopAhead? next = routeStops.nextStop(
        _metersAtIndex(_straight, 10) - 20,
      );
      expect(next?.stop.id, 'c');
    });

    test('depois da última parada não há próxima numa linha não circular',
        () {
      final RouteStops routeStops = RouteStops(_straight, stops);
      expect(routeStops.isCircular, isFalse);
      expect(routeStops.nextStop(_metersAtIndex(_straight, 18)), isNull);
    });

    test('distância até uma parada que já passou é nula (não circular)', () {
      final RouteStops routeStops = RouteStops(_straight, stops);
      final double busMeters = _metersAtIndex(_straight, 12);
      expect(routeStops.metersTo(stops[1], busMeters), isNull);
      expect(
        routeStops.metersTo(stops[0], busMeters),
        closeTo(3 * _segment, 1),
      );
    });

    test('na linha circular a parada da volta não vira a da ida', () {
      final List<Stop> loopStops = <Stop>[
        _stop('ida', 1, _loop[5]),
        _stop('retorno', 2, _loop[20]),
        // Mesmo lugar da parada "ida", mas do outro lado da rua (volta).
        _stop('volta', 3, const LatLng(-27.09999, -52.615)),
      ];
      final RouteStops routeStops = RouteStops(_loop, loopStops);
      expect(routeStops.isCircular, isTrue);

      // Ônibus no índice 8 (ida): a próxima é o retorno, não a "volta".
      final StopAhead? next =
          routeStops.nextStop(_metersAtIndex(_loop, 8));
      expect(next?.stop.id, 'retorno');

      // A "volta" fica depois do retorno (~15 trechos depois dele).
      final double toVolta =
          routeStops.metersTo(loopStops[2], _metersAtIndex(_loop, 8))!;
      expect(
        toVolta,
        closeTo(_metersAtIndex(_loop, 35) - _metersAtIndex(_loop, 8), 5),
      );
    });

    test('na linha circular uma parada que já passou é a da próxima volta',
        () {
      final List<Stop> loopStops = <Stop>[
        _stop('ida', 1, _loop[5]),
        _stop('retorno', 2, _loop[20]),
      ];
      final RouteStops routeStops = RouteStops(_loop, loopStops);
      final double busMeters = _metersAtIndex(_loop, 30);
      expect(
        routeStops.metersTo(loopStops[0], busMeters),
        closeTo(
          routeStops.totalMeters - busMeters + _metersAtIndex(_loop, 5),
          5,
        ),
      );
      // Depois da última parada, a próxima é a primeira de novo.
      expect(routeStops.nextStop(busMeters)?.stop.id, 'ida');
    });
  });

  group('RouteTracker', () {
    test('localiza o ônibus sobre a rota e mede a distância percorrida', () {
      final RouteTracker tracker = RouteTracker();
      final RouteSnap? snap = tracker.locate(
        _straight,
        const LatLng(-27.10001, -52.6145),
      );
      expect(snap, isNotNull);
      final RouteStops routeStops = RouteStops(_straight, const <Stop>[]);
      expect(routeStops.metersAt(snap!), closeTo(5.5 * _segment, 2));
    });

    test('ônibus longe da rota não é localizado', () {
      final RouteTracker tracker = RouteTracker();
      expect(
        tracker.locate(_straight, const LatLng(-27.12, -52.61)),
        isNull,
      );
    });
  });
}
