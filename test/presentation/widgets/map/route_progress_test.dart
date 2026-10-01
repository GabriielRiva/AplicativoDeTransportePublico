import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trancity/presentation/widgets/map/route_progress.dart';

/// Rota circular de teste: ida para leste (índices 0..20, ~111 m entre
/// pontos) e volta pelo mesmo corredor, ~1 m ao norte (índices 21..40).
List<LatLng> _loopRoute() {
  return <LatLng>[
    for (int i = 0; i <= 20; i++) LatLng(0, i * 0.001),
    for (int k = 1; k <= 20; k++) LatLng(0.00001, 0.02 - k * 0.001),
  ];
}

void main() {
  group('RouteProgress', () {
    test('busca global pode cair na volta numa rota circular', () {
      // Ponto da ida com GPS ~1 m ao norte: o mais próximo é o da volta.
      final int index = RouteProgress.nearestIndex(
        _loopRoute(),
        const LatLng(0.00001, 0.005),
      );
      expect(index, 35);
    });

    test('advance mantém o ônibus na ida a partir do último índice', () {
      final int index = RouteProgress.advance(
        _loopRoute(),
        const LatLng(0.00001, 0.005),
        fromIndex: 0,
      );
      expect(index, 5);
    });

    test('advance segue para a volta depois de passar pelo retorno', () {
      final int index = RouteProgress.advance(
        _loopRoute(),
        const LatLng(0.00001, 0.015),
        fromIndex: 19,
      );
      expect(index, 25);
    });

    test('advance não retrocede com GPS levemente atrás', () {
      final int index = RouteProgress.advance(
        _loopRoute(),
        const LatLng(0, 0.0095),
        fromIndex: 10,
      );
      expect(index, 10);
    });

    test('advance recorre à busca global quando a janela está longe', () {
      final int index = RouteProgress.advance(
        _loopRoute(),
        const LatLng(0, 0.015),
        fromIndex: 0,
      );
      expect(index, 15);
    });

    test('rota vazia retorna 0', () {
      expect(
        RouteProgress.advance(
          const <LatLng>[],
          const LatLng(0, 0),
          fromIndex: 3,
        ),
        0,
      );
    });
  });
}
