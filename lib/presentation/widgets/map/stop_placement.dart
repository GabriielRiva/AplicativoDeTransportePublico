import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/utils/map_utils.dart';
import 'route_progress.dart';

/// Posição de desenho do abrigo de uma parada: na calçada, ao lado da rua,
/// e não em cima do traçado da linha.
///
/// Só muda onde o ícone aparece no mapa. A coordenada cadastrada da parada
/// continua sendo usada para detectar a chegada do ônibus
/// (FindStopAtPosition).
abstract final class StopPlacement {
  /// Distância (m) entre o centro da rua e o abrigo desenhado.
  static const double defaultOffsetMeters = 10;

  /// Abaixo desta distância (m) da rua a parada é considerada "no meio da
  /// rua" (ponto cadastrado sobre o traçado) e vai para o lado direito.
  static const double _onRoadToleranceMeters = 3;

  /// Posição do abrigo da parada [stop] em relação ao traçado [route].
  ///
  /// - Parada já afastada da rua (≥ [offsetMeters]): fica onde está.
  /// - Parada perto da rua, mas de um lado dela: vai para esse lado, a
  ///   [offsetMeters] do centro.
  /// - Parada sobre a rua: vai para a direita do sentido da linha, lado em
  ///   que os passageiros embarcam no Brasil.
  static LatLng roadside(
    LatLng stop,
    List<LatLng> route, {
    double offsetMeters = defaultOffsetMeters,
  }) {
    if (route.length < 2) return stop;
    final int index = RouteProgress.nearestIndex(route, stop);
    final RouteSnap snap = RouteProgress.snap(route, stop, index);
    final LatLng from = route[snap.segmentStart];
    final LatLng to = route[snap.segmentStart + 1];
    if (from == to) return stop;

    final double distanceMeters =
        MapUtils.distanceInKm(snap.point, stop) * 1000;
    if (distanceMeters >= offsetMeters) return stop;

    final double roadBearing = MapUtils.bearing(from, to);
    double side = 90;
    if (distanceMeters > _onRoadToleranceMeters) {
      final double toStop = MapUtils.bearing(snap.point, stop);
      final double relative = ((toStop - roadBearing) % 360 + 360) % 360;
      side = relative < 180 ? 90 : -90;
    }
    return MapUtils.offset(snap.point, roadBearing + side, offsetMeters);
  }
}
